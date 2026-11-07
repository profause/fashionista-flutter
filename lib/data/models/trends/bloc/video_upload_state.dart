import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';

enum VideoUploadPhase {
  idle,
  authorizing,
  uploading,
  saving,
  completed,
  failed,
  cancelled,
}

class VideoUploadState extends Equatable {
  final VideoUploadPhase phase;

  /// 0..1 while uploading.
  final double progress;
  final String? error;

  /// The uploaded media once Cloudinary accepted the file.
  final FeaturedMediaModel? media;
  final String? trendId;

  /// The upload finished but the Firestore write did not.
  final bool publishFailedOnly;

  const VideoUploadState({
    this.phase = VideoUploadPhase.idle,
    this.progress = 0,
    this.error,
    this.media,
    this.trendId,
    this.publishFailedOnly = false,
  });

  bool get isBusy =>
      phase == VideoUploadPhase.authorizing ||
      phase == VideoUploadPhase.uploading ||
      phase == VideoUploadPhase.saving;

  bool get isFinished =>
      phase == VideoUploadPhase.completed ||
      phase == VideoUploadPhase.failed ||
      phase == VideoUploadPhase.cancelled;

  VideoUploadState copyWith({
    VideoUploadPhase? phase,
    double? progress,
    String? error,
    FeaturedMediaModel? media,
    String? trendId,
    bool? publishFailedOnly,
    bool clearError = false,
  }) {
    return VideoUploadState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
      media: media ?? this.media,
      trendId: trendId ?? this.trendId,
      publishFailedOnly: publishFailedOnly ?? this.publishFailedOnly,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    progress,
    error,
    media,
    trendId,
    publishFailedOnly,
  ];
}
