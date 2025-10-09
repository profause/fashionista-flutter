import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/bloc/designer_review_bloc_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_review_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/data/services/hive/hive_designer_reviews_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerReviewBloc
    extends Bloc<DesignerReviewBlocEvent, DesignerReviewBlocState> {
  DesignerReviewBloc() : super(const DesignerReviewInitial()) {
    on<LoadDesignerReview>(_onLoadDesignerReview);
    on<LoadDesignerReviewCacheFirstThenNetwork>(
      _onLoadDesignerReviewCacheFirstThenNetwork,
    );
    on<DeleteDesignerReview>(_deleteDesignerReview);
    on<ClearDesignerReview>(
      (event, emit) => emit(const DesignerReviewInitial()),
    );
  }

  Future<void> _onLoadDesignerReview(
    LoadDesignerReview event,
    Emitter<DesignerReviewBlocState> emit,
  ) async {
    emit(const DesignerReviewLoading());
    final result = await sl<FirebaseDesignersService>().findDesignerReviews(
      event.refId,
    );

    result.fold((failure) => emit(DesignerReviewError(failure.toString())), (
      designCollections,
    ) {
      if (designCollections.isEmpty) {
        emit(const DesignerReviewEmpty());
      } else {
        emit(DesignerReviewsLoaded(designCollections));
      }
    });
  }

  Future<void> _deleteDesignerReview(
    DeleteDesignerReview event,
    Emitter<DesignerReviewBlocState> emit,
  ) async {
    final cachedItems = await sl<HiveDesignerReviewsService>().getItems(
      event.designerReviewModel.refId,
    );

    // ✅ find index by matching uid
    final index = cachedItems.indexWhere(
      (item) => item.uid == event.designerReviewModel.uid,
    );
    if (index != -1) {
      cachedItems.removeAt(index);
      try {
        // ✅ persist updated list back to Hive
        await sl<HiveDesignerReviewsService>().insertItems(
          event.designerReviewModel.refId,
          items: cachedItems,
        );

        if (cachedItems.isEmpty) {
          emit(const DesignerReviewEmpty());
          return;
        }

        emit(DesignerReviewsLoaded(cachedItems, fromCache: true));
      } catch (e) {
        // ❌ Rollback if persistence failed (optional)
        emit(DesignerReviewError("Failed to delete item: $e"));
      }
    }
  }

  Future<void> _onLoadDesignerReviewCacheFirstThenNetwork(
    LoadDesignerReviewCacheFirstThenNetwork event,
    Emitter<DesignerReviewBlocState> emit,
  ) async {
    emit(const DesignerReviewLoading());

    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveDesignerReviewsService>().getItems(
      event.refId,
    );
    if (cachedItems.isNotEmpty) {
      emit(DesignerReviewsLoaded(cachedItems, fromCache: true));
    }
    final result = await sl<FirebaseDesignersService>().findDesignerReviews(
      event.refId,
    );

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(DesignerReviewError(failure.toString()));
        }
      },
      (designReviews) async {
        if (designReviews.isEmpty) {
          if (cachedItems.isEmpty) {
            emit(const DesignerReviewEmpty());
          }
          return;
        }

        final isDataChanged =
            cachedItems.toString() != designReviews.toString();

        if (isDataChanged) {
          emit(DesignerReviewsLoaded(designReviews, fromCache: false));
          // 4️⃣ Update cache and emit fresh data
          await sl<HiveDesignerReviewsService>().insertItems(
            event.refId,
            items: designReviews,
          );
          // 🔑 Do NOT call `on<Event>` here again!
        } else {
          // no change
          emit(DesignerReviewsLoaded(cachedItems, fromCache: true));
        }
      },
    );
  }
}
