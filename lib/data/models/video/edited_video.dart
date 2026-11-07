import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/video/video_metadata.dart';

/// What the editor hands back to the composer: a local file ready to upload.
class EditedVideo extends Equatable {
  final String path;
  final Duration duration;
  final int width;
  final int height;
  final bool hasAudio;
  final int fileSize;
  final bool wasReencoded;

  const EditedVideo({
    required this.path,
    required this.duration,
    required this.width,
    required this.height,
    required this.hasAudio,
    required this.fileSize,
    this.wasReencoded = true,
  });

  factory EditedVideo.fromProcessed(ProcessedVideo processed) {
    return EditedVideo(
      path: processed.path,
      duration: processed.duration,
      width: processed.width,
      height: processed.height,
      hasAudio: processed.hasAudio,
      fileSize: processed.fileSize,
      wasReencoded: processed.wasReencoded,
    );
  }

  bool get fileExists => File(path).existsSync();

  double get aspectRatio => height == 0 ? 9 / 16 : width / height;

  String get sizeLabel {
    final megabytes = fileSize / (1024 * 1024);
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
    path,
    duration,
    width,
    height,
    hasAudio,
    fileSize,
    wasReencoded,
  ];
}
