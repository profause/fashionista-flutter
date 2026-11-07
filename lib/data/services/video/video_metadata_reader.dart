import 'dart:io';

import 'package:fashionista/data/models/video/video_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Reads duration, dimensions and file size of a local clip.
///
/// `video_player` is the only dependency that exposes duration and size without
/// a platform channel of our own, so a short-lived controller is created and
/// disposed immediately. Audio-track detection is not exposed at all — callers
/// treat `hasAudio == null` as "probably has audio" (plan §5 Q2).
class VideoMetadataReader {
  const VideoMetadataReader();

  Future<VideoMetadata?> read(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final size = await file.length();
    VideoPlayerController? controller;

    try {
      controller = VideoPlayerController.file(file);
      await controller.initialize();

      final value = controller.value;
      final dimensions = value.size;
      if (dimensions.width <= 0 || dimensions.height <= 0) return null;

      return VideoMetadata(
        duration: value.duration,
        width: dimensions.width.round(),
        height: dimensions.height.round(),
        fileSize: size,
      );
    } catch (error) {
      debugPrint('Video inspection failed for $path: $error');
      return null;
    } finally {
      await controller?.dispose();
    }
  }
}
