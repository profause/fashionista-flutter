import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_video_upload_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/data/services/hive/hive_video_delete_token_service.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_usecase.dart';
import 'package:fashionista/domain/usecases/trends/delete_trend_usecase.dart';
import 'package:fashionista/domain/usecases/trends/find_trend_by_id_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      final viewerId = FirebaseAuth.instance.currentUser?.uid;
      if (cachedItem.isReported && cachedItem.createdBy != viewerId) {
        emit(const TrendError('This trend is no longer available.'));
        return;
      }
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
      // Video posts own a Cloudinary asset. Remove it first: if that fails the
      // document stays, so the user can retry instead of leaving an orphan
      // (plan §8, milestone 5).
      final cached = await sl<HiveTrendService>().getItem(event.uid);
      final videoAssets = cached.featuredMedia
          .where((media) => media.isVideo)
          .map((media) => media.uid)
          .whereType<String>()
          .where((assetId) => assetId.isNotEmpty)
          .toList(growable: false);

      for (final assetId in videoAssets) {
        final deleted = await _deleteVideoAsset(
          assetId: assetId,
          trendId: event.uid,
        );
        if (!deleted) {
          emit(
            const TrendError(
              'The video could not be removed. Please try again.',
            ),
          );
          return;
        }
      }

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

  /// Removes a video from Cloudinary: the delete token first (no backend round
  /// trip, but only valid for 10 minutes after the upload), then the Admin API
  /// through the `deleteCloudinaryAsset` callable.
  Future<bool> _deleteVideoAsset({
    required String assetId,
    required String trendId,
  }) async {
    final tokens = sl<HiveVideoDeleteTokenService>();
    final uploads = sl<FirebaseVideoUploadService>();

    final token = await tokens.tokenFor(assetId);
    if (token != null && await uploads.deleteByToken(token)) {
      await tokens.remove(assetId);
      return true;
    }

    return uploads.deleteAsset(assetId: assetId, trendId: trendId);
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
