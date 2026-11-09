import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/bloc/video_editor_state.dart';

enum VideoCaptureStage { initializing, ready, recording, recorded, error }

class VideoCaptureState extends Equatable {
  final VideoCaptureStage stage;
  final int cameraCount;
  final bool isFrontCamera;
  final Duration elapsed;
  final Duration maxDuration;
  final String? recordedPath;
  final String? error;

  /// Microphone was denied, so recordings are silent.
  final bool isMuted;

  /// Frame the user is composing. The camera records full-frame; this ratio is
  /// the framing guide and the crop the editor opens with.
  final VideoAspectPreset aspect;

  /// Torch is on (back camera only).
  final bool isTorchOn;

  /// False when the camera reported that it has no torch.
  final bool isTorchAvailable;

  const VideoCaptureState({
    this.stage = VideoCaptureStage.initializing,
    this.cameraCount = 0,
    this.isFrontCamera = false,
    this.elapsed = Duration.zero,
    this.maxDuration = const Duration(seconds: 30),
    this.recordedPath,
    this.error,
    this.isMuted = false,
    this.aspect = VideoAspectPreset.portrait,
    this.isTorchOn = false,
    this.isTorchAvailable = true,
  });

  bool get isRecording => stage == VideoCaptureStage.recording;

  double get progress {
    final total = maxDuration.inMilliseconds;
    if (total <= 0) return 0;
    return (elapsed.inMilliseconds / total).clamp(0, 1).toDouble();
  }

  String get remainingLabel {
    final remaining = maxDuration - elapsed;
    final seconds = remaining.inSeconds.clamp(0, 99);
    return '0:${seconds.toString().padLeft(2, '0')}';
  }

  VideoCaptureState copyWith({
    VideoCaptureStage? stage,
    int? cameraCount,
    bool? isFrontCamera,
    Duration? elapsed,
    Duration? maxDuration,
    String? recordedPath,
    String? error,
    bool? isMuted,
    VideoAspectPreset? aspect,
    bool? isTorchOn,
    bool? isTorchAvailable,
    bool clearError = false,
    bool clearRecording = false,
  }) {
    return VideoCaptureState(
      stage: stage ?? this.stage,
      cameraCount: cameraCount ?? this.cameraCount,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      elapsed: elapsed ?? this.elapsed,
      maxDuration: maxDuration ?? this.maxDuration,
      recordedPath: clearRecording ? null : recordedPath ?? this.recordedPath,
      error: clearError ? null : error ?? this.error,
      isMuted: isMuted ?? this.isMuted,
      aspect: aspect ?? this.aspect,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      isTorchAvailable: isTorchAvailable ?? this.isTorchAvailable,
    );
  }

  @override
  List<Object?> get props => [
    stage,
    cameraCount,
    isFrontCamera,
    elapsed,
    maxDuration,
    recordedPath,
    error,
    isMuted,
    aspect,
    isTorchOn,
    isTorchAvailable,
  ];
}
