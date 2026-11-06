import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_usecase.dart';
import 'package:fashionista/domain/usecases/trends/delete_trend_usecase.dart';
import 'package:fashionista/domain/usecases/trends/find_trend_by_id_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendBloc extends Bloc<TrendBlocEvent, TrendBlocState> {
  TrendBloc() : super(const TrendInitial()) {
    on<LoadTrend>(_onLoadTrend);
    on<AddTrend>(_addTrend);
    on<UpdateTrend>(_updateTrend);
    on<DeleteTrend>(_deleteTrend);
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

  Future<void> _updateTrend(
    UpdateTrend event,
    Emitter<TrendBlocState> emit,
  ) async {
    emit(TrendLoading());
    await sl<HiveTrendService>().updateItem(event.trend);
    emit(TrendUpdated(event.trend));
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
