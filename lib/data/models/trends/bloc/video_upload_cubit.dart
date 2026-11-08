import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/trends/bloc/video_upload_state.dart';
import 'package:fashionista/data/models/video/pending_publish_task.dart';
import 'package:fashionista/data/models/video/video_upload_models.dart';
import 'package:fashionista/data/services/firebase/firebase_video_upload_service.dart';
import 'package:fashionista/data/services/hive/hive_upload_task_service.dart';
import 'package:fashionista/data/services/hive/hive_video_delete_token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Writes the trend document for an uploaded video.
typedef TrendVideoPublisher =
    Future<void> Function({
      required String trendId,
      required FeaturedMediaModel media,
    });

/// Orchestrates upload → publish, with cancel and retry.
///
/// Uploads are unsigned (plan §19): there is no authorization round-trip, only
/// a Cloudinary upload followed by the Firestore write.
class VideoUploadCubit extends Cubit<VideoUploadState> {
  VideoUploadCubit({
    FirebaseVideoUploadService? service,
    HiveUploadTaskService? pendingTasks,
    HiveVideoDeleteTokenService? deleteTokens,
  }) : _service = service ?? FirebaseVideoUploadService(),
       _pendingTasks = pendingTasks ?? HiveUploadTaskService(),
       _deleteTokens = deleteTokens ?? HiveVideoDeleteTokenService(),
       super(const VideoUploadState());

  final FirebaseVideoUploadService _service;
  final HiveUploadTaskService _pendingTasks;
  final HiveVideoDeleteTokenService _deleteTokens;

  CancelToken? _cancelToken;
  File? _file;
  bool _hasAudio = true;
  TrendVideoPublisher? _publish;
  CloudinaryVideoAsset? _uploaded;

  Future<void> start({
    required String trendId,
    required String videoPath,
    required bool hasAudio,
    required TrendVideoPublisher publish,
  }) async {
    _file = File(videoPath);
    _hasAudio = hasAudio;
    _publish = publish;

    emit(VideoUploadState(phase: VideoUploadPhase.uploading, trendId: trendId));

    await _run(trendId);
  }

  /// Retries from the last failure: re-publishes when only the save failed,
  /// otherwise uploads the file again.
  Future<void> retry() async {
    final trendId = state.trendId;
    if (trendId == null) return;

    if (state.publishFailedOnly && _uploaded != null) {
      emit(state.copyWith(phase: VideoUploadPhase.saving, clearError: true));
      await _publishMedia(trendId, _uploaded!.toMedia(hasAudio: _hasAudio));
      return;
    }

    emit(
      state.copyWith(
        phase: VideoUploadPhase.uploading,
        progress: 0,
        clearError: true,
        publishFailedOnly: false,
      ),
    );
    await _run(trendId);
  }

  /// Cancels the transfer and removes a partially uploaded asset.
  Future<void> cancel() async {
    if (!state.isCancellable) return;

    _cancelToken?.cancel('cancelled by user');
    _cancelToken = null;

    final uploaded = _uploaded;
    if (uploaded != null) {
      await _discardAsset(uploaded);
      _uploaded = null;
    }

    emit(state.copyWith(phase: VideoUploadPhase.cancelled));
  }

  Future<void> _run(String trendId) async {
    final file = _file;
    if (file == null) {
      emit(
        state.copyWith(
          phase: VideoUploadPhase.failed,
          error: 'No video selected.',
        ),
      );
      return;
    }

    final token = CancelToken();
    _cancelToken = token;

    CloudinaryVideoAsset asset;
    try {
      asset = await _upload(file, token);
    } on VideoUploadException catch (error) {
      if (state.phase == VideoUploadPhase.cancelled) return;
      emit(
        state.copyWith(phase: VideoUploadPhase.failed, error: error.message),
      );
      return;
    }

    _uploaded = asset;
    _cancelToken = null;

    // The token is the only client-side way to delete this asset later, so it
    // is kept before the post exists at all.
    final deleteToken = asset.deleteToken;
    if (deleteToken != null) {
      await _deleteTokens.save(assetId: asset.assetId, token: deleteToken);
    }

    emit(state.copyWith(phase: VideoUploadPhase.saving, progress: 1));
    await _publishMedia(trendId, asset.toMedia(hasAudio: _hasAudio));
  }

  Future<CloudinaryVideoAsset> _upload(File file, CancelToken token) {
    emit(state.copyWith(phase: VideoUploadPhase.uploading, progress: 0));

    return _service.upload(
      file: file,
      cancelToken: token,
      onProgress: (sent, total) {
        if (total <= 0 || isClosed) return;
        emit(state.copyWith(progress: (sent / total).clamp(0, 1).toDouble()));
      },
    );
  }

  /// Removes an asset that never became a post: token first (no backend round
  /// trip), then the Admin API once the token has expired.
  Future<void> _discardAsset(CloudinaryVideoAsset asset) async {
    final token = asset.deleteToken;
    var deleted = token != null && await _service.deleteByToken(token);

    if (!deleted) {
      final trendId = state.trendId;
      if (trendId != null) {
        deleted = await _service.deleteAsset(
          assetId: asset.assetId,
          trendId: trendId,
        );
      }
    }

    if (deleted) {
      await _deleteTokens.remove(asset.assetId);
    }
  }

  Future<void> _publishMedia(String trendId, FeaturedMediaModel media) async {
    final publish = _publish;
    if (publish == null) return;

    try {
      await publish(trendId: trendId, media: media);
      await _pendingTasks.remove(trendId);

      emit(
        state.copyWith(
          phase: VideoUploadPhase.completed,
          media: media,
          trendId: trendId,
          publishFailedOnly: false,
          clearError: true,
        ),
      );
    } catch (error) {
      debugPrint('Video publish failed: $error');

      // Keep enough information to retry the write without re-uploading.
      await _pendingTasks.save(
        PendingPublishTask(
          trendId: trendId,
          media: media,
          createdAt: DateTime.now().toUtc(),
        ),
      );

      emit(
        state.copyWith(
          phase: VideoUploadPhase.failed,
          media: media,
          error: 'The video uploaded but the post could not be saved.',
          publishFailedOnly: true,
        ),
      );
    }
  }
}
