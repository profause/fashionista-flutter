import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_usecase.dart';
import 'package:fashionista/domain/usecases/trends/delete_trend_usecase.dart';
import 'package:fashionista/domain/usecases/trends/find_trend_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/trends/find_trends_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendBloc extends Bloc<TrendBlocEvent, TrendBlocState> {
  TrendBloc() : super(const TrendInitial()) {
    on<LoadTrend>(_onLoadTrend);
    on<LoadTrends>(_onLoadTrends);
    on<AddTrend>(_addTrend);
    on<UpdateTrend>(_updateTrend);
    on<DeleteTrend>(_deleteTrend);
    on<LoadTrendsCacheFirstThenNetwork>(_onLoadTrendsCacheFirstThenNetwork);
    on<LoadTrendsCacheFirst>(_loadCacheFirst);
    on<LoadTrendsCacheForYouPage>(_onLoadTrendsCacheForYouPage);

    on<ClearTrend>((event, emit) => emit(const TrendInitial()));
  }

  Future<void> _onLoadTrend(
    LoadTrend event,
    Emitter<TrendBlocState> emit,
  ) async {
    emit(const TrendLoading());
    if (event.isFromCache) {
      // 1️⃣ Try cache first
      final cachedItem = await sl<HiveTrendService>().getItem(event.uid);
      emit(TrendUpdated(cachedItem));
    } else {
      final result = await sl<FindTrendByIdUsecase>().call(event.uid);
      result.fold(
        (failure) => emit(TrendError(failure.toString())),
        (trend) => emit(TrendUpdated(trend)),
      );
    }
  }

  Future<void> _addTrend(AddTrend event, Emitter<TrendBlocState> emit) async {
    emit(TrendLoading());
    final result = await sl<AddTrendUsecase>().call(event.trend);
    await result.fold(
      (failure) async {
        emit(TrendError(failure.toString()));
      },
      (client) async {
        await sl<HiveTrendService>().addItem(event.trend);
        emit(TrendAdded(client)); // ✅ safe emit
      },
    );
  }

  Future<void> _deleteTrend(
    DeleteTrend event,
    Emitter<TrendBlocState> emit,
  ) async {
    try {
      var result = await sl<DeleteTrendUsecase>().call(event.uid);

      await result.fold(
        (failure) async {
          emit(TrendError(failure.toString()));
        },
        (message) async {
          await sl<HiveTrendService>().deleteItem(event.uid);
          emit(TrendDeleted(message)); // ✅ safe emit
        },
      );
    } catch (e) {
      // ❌ Rollback if persistence failed (optional)
      emit(TrendError("Failed to delete item: $e"));
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
    await sl<HiveTrendService>().updateItem(event.trend);
    emit(TrendUpdated(event.trend));
  }

  Future<void> _onLoadTrendsCacheFirstThenNetwork(
    LoadTrendsCacheFirstThenNetwork event,
    Emitter<TrendBlocState> emit,
  ) async {
    try {
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
      final result = await sl<FirebaseTrendsService>().fetchTrends(10);

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
              await sl<HiveTrendService>().insertItems(trends);
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
    } catch (e) {
      if (emit.isDone) return; // <- safeguard
      emit(TrendError(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  //  CACHE FIRST → NETWORK REFRESH (Shared by all pages)
  // ---------------------------------------------------------------------------

  Future<void> _loadCacheFirst(LoadTrendsCacheFirst event, Emitter emit) async {
    emit(const TrendLoading());

    final cached = await sl<HiveTrendService>().getItems("");

    // Show cached immediately if available
    if (cached.isNotEmpty) {
      emit(TrendsLoaded(cached, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FirebaseTrendsService>().fetchTrends(event.limit!);

    await result.fold(
      // ERROR → only show if nothing in cache
      (failure) async {
        if (cached.isEmpty) emit(TrendError(failure.toString()));
      },

      // SUCCESS
      (networkTrends) async {
        if (networkTrends.isEmpty) {
          if (cached.isEmpty) emit(const TrendsEmpty());
          return;
        }

        // Detect changes (compare IDs only)
        final changed = !_sameIds(cached, networkTrends);

        if (changed) {
          emit(TrendsLoaded(networkTrends, fromCache: false));
          await sl<HiveTrendService>().insertItems(networkTrends);
        } else {
          emit(TrendsLoaded(cached, fromCache: true));
        }
      },
    );
  }

  bool _sameIds(List a, List b) {
    final aIds = a.map((e) => e.uid).toSet();
    final bIds = b.map((e) => e.uid).toSet();
    return aIds.containsAll(bIds) && bIds.containsAll(aIds);
  }

  Future<void> _onLoadTrendsCacheForYouPage(
    LoadTrendsCacheForYouPage event,
    Emitter<TrendBlocState> emit,
  ) async {
    emit(const TrendLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveTrendService>().getItemsBelongsTo(
      event.uid,
    );

    if (cachedItems.isEmpty) {
      emit(const TrendsEmpty());
      return;
    }
    //if (cachedItems.isNotEmpty) {
    emit(TrendsCreatedByLoaded(cachedItems, fromCache: true));
    //}
  }
}
