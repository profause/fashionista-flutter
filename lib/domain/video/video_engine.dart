import 'package:fashionista/data/models/video/video_metadata.dart';

/// Platform-agnostic video processing.
///
/// The UI never imports `native_video_editor` directly: this interface is what
/// keeps the engine replaceable (the package is young — see plan §11 R1) and
/// what lets the editor and upload cubits be unit tested with a fake.
abstract class VideoEngine {
  /// Maximum length of a published trend video.
  static const Duration maxDuration = Duration(seconds: 30);

  /// Minimum selection the editor will export.
  static const Duration minDuration = Duration(seconds: 1);

  Future<VideoMetadata> inspect(String path);

  /// Trims, crops, resizes and optionally strips audio in a single native pass.
  ///
  /// When nothing would change (full-length clip, no crop, audio kept) the
  /// source is returned untouched instead of being re-encoded.
  Future<ProcessedVideo> process({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
    required VideoCrop crop,
    required bool muteAudio,
    required VideoOutputSettings settings,
    void Function(double progress)? onProgress,
  });

  /// Writes one frame to a temp file and returns its path.
  Future<String> thumbnail(String path, {required Duration at});

  /// Cancels an in-flight [process] for [outputPath].
  Future<void> cancel(String outputPath);
}
