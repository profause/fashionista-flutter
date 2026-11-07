import 'dart:io';

import 'package:fashionista/data/models/video/video_metadata.dart';
import 'package:fashionista/data/services/video/video_metadata_reader.dart';
import 'package:fashionista/domain/video/video_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:native_video_editor/native_video_editor.dart' as editor;
import 'package:path_provider/path_provider.dart';

/// [VideoEngine] backed by `native_video_editor` (AndroidX Media3 Transformer
/// on Android, AVFoundation on iOS).
class NativeVideoEditorEngine implements VideoEngine {
  NativeVideoEditorEngine({VideoMetadataReader? reader})
    : _reader = reader ?? const VideoMetadataReader();

  final VideoMetadataReader _reader;

  /// Sub-directory of the app's temp dir holding exports and thumbnails.
  static const String workspaceName = 'trends_video';

  @override
  Future<VideoMetadata> inspect(String path) async {
    final metadata = await _reader.read(path);
    if (metadata == null) {
      throw const VideoEngineException(
        'That video could not be read. Try another file.',
      );
    }
    return metadata;
  }

  @override
  Future<ProcessedVideo> process({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
    required VideoCrop crop,
    required bool muteAudio,
    required VideoOutputSettings settings,
    void Function(double progress)? onProgress,
  }) async {
    final source = await inspect(inputPath);
    final startClamped = _clamp(start, source.duration);
    final endClamped = _clamp(end, source.duration);

    if (endClamped <= startClamped) {
      throw const VideoEngineException('Select at least one second to export.');
    }

    final selection = endClamped - startClamped;
    if (selection > VideoEngine.maxDuration) {
      throw const VideoEngineException(
        'Videos can be at most 30 seconds long.',
      );
    }

    // Nothing to change: upload the original rather than re-encoding it.
    final isFullLength =
        startClamped == Duration.zero && endClamped >= source.duration;
    if (isFullLength && crop.isFullFrame && !muteAudio) {
      return ProcessedVideo(
        path: inputPath,
        duration: source.duration,
        width: source.width,
        height: source.height,
        hasAudio: source.hasAudio ?? true,
        fileSize: source.fileSize,
        wasReencoded: false,
      );
    }

    final target = settings.targetSize(
      sourceWidth: source.width,
      sourceHeight: source.height,
      crop: crop,
    );

    await ensureWorkspace();
    final request = editor.VideoEditRequest(
      inputPath: inputPath,
      outputPath: outputPath,
      trimStart: startClamped,
      trimEnd: endClamped,
      cropRect: crop.isFullFrame
          ? null
          : editor.VideoCropRect(
              left: crop.left,
              top: crop.top,
              width: crop.width,
              height: crop.height,
            ),
      targetWidth: target.width,
      targetHeight: target.height,
      muteAudio: muteAudio,
    );

    final resultPath = await editor.NativeVideoEditor.processVideo(
      request,
      onProgress: onProgress,
    );

    final output = File(resultPath);
    if (!await output.exists()) {
      throw const VideoEngineException('The edited video was not created.');
    }

    return ProcessedVideo(
      path: resultPath,
      duration: selection,
      width: target.width,
      height: target.height,
      hasAudio: muteAudio ? false : (source.hasAudio ?? true),
      fileSize: await output.length(),
    );
  }

  @override
  Future<String> thumbnail(String path, {required Duration at}) async {
    final directory = await ensureWorkspace();
    final fileName = '${_hash(path)}_${at.inMilliseconds}.jpg';
    final outputFile = File('${directory.path}/$fileName');

    // A repeated open of the editor must not pay for the same frame twice.
    if (await outputFile.exists()) return outputFile.path;

    return editor.NativeVideoEditor.extractThumbnail(
      editor.VideoThumbnailRequest(
        inputPath: path,
        outputPath: outputFile.path,
        position: at,
        quality: 80,
      ),
    );
  }

  @override
  Future<void> cancel(String outputPath) {
    return editor.NativeVideoEditor.cancelProcessVideo(outputPath);
  }

  /// Creates `<temp>/trends_video` and returns it.
  static Future<Directory> ensureWorkspace() async {
    final temp = await getTemporaryDirectory();
    final directory = Directory('${temp.path}/$workspaceName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Removes stale exports and thumbnails; called once at app start.
  static Future<void> sweepTempFiles({
    Duration olderThan = const Duration(days: 2),
  }) async {
    try {
      final directory = await ensureWorkspace();
      final cutoff = DateTime.now().subtract(olderThan);

      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (error) {
      debugPrint('Video temp sweep failed: $error');
    }
  }

  static Duration _clamp(Duration value, Duration max) {
    if (value < Duration.zero) return Duration.zero;
    if (value > max) return max;
    return value;
  }

  static int _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

/// A user-presentable processing failure.
class VideoEngineException implements Exception {
  final String message;
  const VideoEngineException(this.message);

  @override
  String toString() => message;
}
