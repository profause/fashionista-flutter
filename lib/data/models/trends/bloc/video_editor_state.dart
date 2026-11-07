import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/video/video_metadata.dart';

enum VideoEditorStage { loading, ready, exporting, exported, error }

enum VideoAspectPreset {
  original('Original', null),
  portrait('9:16', 9 / 16),
  portraitFourFive('4:5', 4 / 5),
  square('1:1', 1);

  const VideoAspectPreset(this.label, this.aspect);

  final String label;

  /// `null` means "keep the source frame".
  final double? aspect;
}

class VideoEditorState extends Equatable {
  final VideoEditorStage stage;
  final String? sourcePath;
  final VideoMetadata? metadata;
  final Duration trimStart;
  final Duration trimEnd;

  /// 0..1 export progress.
  final double progress;
  final ProcessedVideo? exported;
  final String? error;

  /// Filmstrip frames written to temp files.
  final List<String> thumbnails;

  final VideoAspectPreset aspect;
  final bool muteAudio;

  const VideoEditorState({
    this.stage = VideoEditorStage.loading,
    this.sourcePath,
    this.metadata,
    this.trimStart = Duration.zero,
    this.trimEnd = Duration.zero,
    this.progress = 0,
    this.exported,
    this.error,
    this.thumbnails = const [],
    this.aspect = VideoAspectPreset.original,
    this.muteAudio = false,
  });

  Duration get selection => trimEnd - trimStart;

  bool get isExporting => stage == VideoEditorStage.exporting;

  bool get canExport =>
      stage != VideoEditorStage.exporting &&
      selection >= const Duration(seconds: 1) &&
      selection <= const Duration(seconds: 30);

  String get durationLabel => '${selection.inSeconds}s';

  VideoEditorState copyWith({
    VideoEditorStage? stage,
    String? sourcePath,
    VideoMetadata? metadata,
    Duration? trimStart,
    Duration? trimEnd,
    double? progress,
    ProcessedVideo? exported,
    String? error,
    List<String>? thumbnails,
    VideoAspectPreset? aspect,
    bool? muteAudio,
    bool clearError = false,
    bool clearExported = false,
  }) {
    return VideoEditorState(
      stage: stage ?? this.stage,
      sourcePath: sourcePath ?? this.sourcePath,
      metadata: metadata ?? this.metadata,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      progress: progress ?? this.progress,
      exported: clearExported ? null : exported ?? this.exported,
      error: clearError ? null : error ?? this.error,
      thumbnails: thumbnails ?? this.thumbnails,
      aspect: aspect ?? this.aspect,
      muteAudio: muteAudio ?? this.muteAudio,
    );
  }

  @override
  List<Object?> get props => [
    stage,
    sourcePath,
    metadata,
    trimStart,
    trimEnd,
    progress,
    exported,
    error,
    thumbnails,
    aspect,
    muteAudio,
  ];
}
