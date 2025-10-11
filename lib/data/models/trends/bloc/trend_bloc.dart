import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/domain/usecases/trends/find_trend_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/trends/find_trends_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendBloc extends Bloc<TrendBlocEvent, TrendBlocState> {
  TrendBloc() : super(const TrendInitial()) {
    on<LoadTrend>(_onLoadTrend);
    on<LoadTrends>(_onLoadTrends);
    on<UpdateTrend>(_updateTrend);
    on<UpdateCachedTrend>(_updateCachedTrend);
    on<DeleteTrend>(_deleteTrend);
    //on<UpdateTrend>((event, emit) => emit(TrendUpdated(event.trend)));
    on<LoadTrendsCacheFirstThenNetwork>(_onLoadTrendsCacheFirstThenNetwork);
    on<LoadTrendsCacheForDiscoverPage>(_onLoadTrendsCacheForDiscoverPage);

    on<ClearTrend>((event, emit) => emit(const TrendInitial()));
  }

  Future<void> _onLoadTrend(
    LoadTrend event,
    Emitter<TrendBlocState> emit,
  ) async {
    emit(const TrendLoading());

    final result = await sl<FindTrendByIdUsecase>().call(event.uid);

    result.fold(
      (failure) => emit(TrendError(failure.toString())),
      (trend) => emit(TrendLoaded(trend)),
    );
  }

  Future<void> _deleteTrend(
    DeleteTrend event,
    Emitter<TrendBlocState> emit,
  ) async {
    // var result = await sl<DeleteTrendUsecase>().call(event.uid);
    // result.fold((l) => null, (r) => emit(TrendDeleted(r)));

    final cachedItems = await sl<HiveTrendService>().getItems(
      event.trend.createdBy,
    );
    // ✅ find index by matching uid
    final index = cachedItems.indexWhere((item) => item.uid == event.trend.uid);

    if (index != -1) {
      cachedItems.removeAt(index);

      try {
        // ✅ persist updated list back to Hive
        await sl<HiveTrendService>().insertItems(
          event.trend.createdBy,
          items: cachedItems,
        );

        if (cachedItems.isEmpty) {
          emit(const TrendsEmpty());
          return;
        }

        emit(TrendsLoaded(cachedItems, fromCache: true));
      } catch (e) {
        // ❌ Rollback if persistence failed (optional)
        if (emit.isDone) return;
        emit(TrendError(e.toString()));
      }
    }
  }

  Future<void> _onLoadTrends(
    LoadTrends event,
    Emitter<TrendBlocState> emit,
  ) async {
    emit(const TrendLoading());

    final result = await sl<FindTrendsUsecase>().call(event.uid);

    result.fold((failure) => emit(TrendError(failure.toString())), (trends) {
      if (trends.isEmpty) {
        emit(const TrendsEmpty());
      } else {
        emit(TrendsLoaded(trends));
      }
    });
  }

  Future<void> _updateTrend(
    UpdateTrend event,
    Emitter<TrendBlocState> emit,
  ) async {
    emit(TrendLoading());
    emit(TrendUpdated(event.trend));
    //emit(TrendLoaded(event.trend));
  }

  Future<void> _updateCachedTrend(
    UpdateCachedTrend event,
    Emitter<TrendBlocState> emit,
  ) async {
    final cachedItems = await sl<HiveTrendService>().getItems('discover');
    //debugPrint('cachedItems: ${event.trend.isLiked}');
    // ✅ find index by matching uid
    final index = cachedItems.indexWhere((item) => item.uid == event.trend.uid);

    if (index != -1) {
      cachedItems.removeAt(index);
      cachedItems.insert(index, event.trend);
      try {
        // ✅ persist updated list back to Hive
        await sl<HiveTrendService>().insertItems(
          'discover',
          items: cachedItems,
        );
      } catch (e) {
        // ❌ Rollback if persistence failed (optional)
        emit(TrendError("Failed to update item: $e"));
      }
    }
    //emit(TrendUpdated(event.trend));
  }

  Future<void> _onLoadTrendsCacheFirstThenNetwork(
    LoadTrendsCacheFirstThenNetwork event,
    Emitter<TrendBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }

    emit(const TrendLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveTrendService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(TrendsLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FindTrendsUsecase>().call(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(TrendError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (trends) async {
        try {
          if (trends.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const TrendsEmpty());
            }
            return;
          }

          // 3️⃣ Detect if data has changed
          // int? cachedFirstTimestamp = cachedItems.isNotEmpty
          //     ? cachedItems.first.createdDate!.millisecondsSinceEpoch
          //     : null;

          // int freshFirstTimestamp =
          //     trends.first.createdDate!.millisecondsSinceEpoch;

          // if (cachedFirstTimestamp == null ||
          //     cachedFirstTimestamp != freshFirstTimestamp) {
          //   emit(TrendsLoaded(trends, fromCache: false));
          //   // 4️⃣ Update cache and emit fresh data
          //   await sl<HiveTrendService>().insertItems(
          //     uid,
          //     items: trends,
          //   );
          //   debugPrint('Trends updated');
          //   // emit(
          //   //   TrendsNewData(trends),
          //   // ); // optional "new data" state
          //   // 🔑 Do NOT call `on<Event>` here again!
          // }

          if (cachedItems.toString() != trends.toString()) {
            emit(TrendsLoaded(trends, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveTrendService>().insertItems(uid, items: trends);
          } else {
            // no change
            emit(TrendsLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(TrendError(e.toString()));
        }
      },
    );
  }

  Future<void> _onLoadTrendsCacheForDiscoverPage(
    LoadTrendsCacheForDiscoverPage event,
    Emitter<TrendBlocState> emit,
  ) async {
    emit(const TrendLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveTrendService>().getItems(event.uid);

    if (cachedItems.isNotEmpty) {
      emit(TrendsLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FirebaseTrendsService>().fetchTrendsWithFilter(10);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(TrendError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (trends) async {
        try {
          if (trends.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const TrendsEmpty());
            }
            return;
          }

          if (cachedItems.toString() != trends.toString()) {
            emit(TrendsLoaded(trends, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveTrendService>().insertItems(event.uid, items: trends);
          } else {
            // no change
            emit(TrendsLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(TrendError(e.toString()));
        }
      },
    );
  }
}
