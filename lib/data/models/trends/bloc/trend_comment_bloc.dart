import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc_state.dart';
import 'package:fashionista/data/services/hive/hive_trend_comment_service.dart';
import 'package:fashionista/domain/usecases/trends/find_trend_comments_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendCommentBloc
    extends Bloc<TrendCommentBlocEvent, TrendCommentBlocState> {
  TrendCommentBloc() : super(const TrendCommentInitial()) {
    on<LoadTrendComments>(_onLoadTrendComments);
    on<LoadTrendCommentsCacheFirstThenNetwork>(
      _onLoadTrendCommentsCacheFirstThenNetwork,
    );
    on<ClearTrendComment>((event, emit) => emit(const TrendCommentInitial()));
  }

  Future<void> _onLoadTrendComments(
    LoadTrendComments event,
    Emitter<TrendCommentBlocState> emit,
  ) async {
    emit(const TrendCommentLoading());
    final result = await sl<FindTrendCommentsUsecase>().call(event.refId);

    result.fold((failure) => emit(TrendCommentError(failure.toString())), (
      designCollections,
    ) {
      if (designCollections.isEmpty) {
        emit(const TrendCommentsEmpty());
      } else {
        emit(TrendCommentsLoaded(designCollections));
      }
    });
  }

  Future<void> _onLoadTrendCommentsCacheFirstThenNetwork(
    LoadTrendCommentsCacheFirstThenNetwork event,
    Emitter<TrendCommentBlocState> emit,
  ) async {
    emit(const TrendCommentLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveTrendCommentService>().getItems(
      event.refId,
    );
    if (cachedItems.isNotEmpty) {
      emit(TrendCommentsLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FindTrendCommentsUsecase>().call(event.refId);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(TrendCommentError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (trendComments) async {
        try {
          if (trendComments.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const TrendCommentsEmpty());
            }
            return;
          }

          // 3️⃣ Detect if data has changed
          int? cachedFirstTimestamp = cachedItems.isNotEmpty
              ? cachedItems.first.createdAt
              : null;
          //int freshFirstTimestamp = designCollections.first.createdAt;

          final isDataChanged =
              cachedItems.toString() != trendComments.toString();

          if (cachedFirstTimestamp == null || isDataChanged) {
            emit(TrendCommentsLoaded(trendComments, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveTrendCommentService>().insertItems(
              event.refId,
              items: trendComments,
            );

            // emit(
            //   DesignCollectionsNewData(designCollections),
            // ); // optional "new data" state
            // 🔑 Do NOT call `on<Event>` here again!
          } else {
            // no change
            emit(TrendCommentsLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(TrendCommentError(e.toString()));
        }
      },
    );
  }
}
