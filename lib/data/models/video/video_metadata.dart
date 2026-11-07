import 'dart:math' as math;

/// What the editor needs to know about a source clip.
class VideoMetadata {
  final Duration duration;
  final int width;
  final int height;
  final int fileSize;

  /// `null` when the platform gave us no reliable answer (see plan §5 Q2).
  final bool? hasAudio;

  const VideoMetadata({
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSize,
    this.hasAudio,
  });

  bool get isPortrait => height >= width;

  double get aspectRatio => height == 0 ? 1 : width / height;

  VideoMetadata copyWith({bool? hasAudio}) {
    return VideoMetadata(
      duration: duration,
      width: width,
      height: height,
      fileSize: fileSize,
      hasAudio: hasAudio ?? this.hasAudio,
    );
  }
}

/// A crop expressed in normalized 0..1 coordinates of the source frame.
///
/// Named `VideoCrop` rather than `VideoCropRect` on purpose: the plugin exports
/// its own `VideoCropRect` and the two would collide wherever both are imported.
class VideoCrop {
  final double left;
  final double top;
  final double width;
  final double height;

  const VideoCrop({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  static const VideoCrop original = VideoCrop(
    left: 0,
    top: 0,
    width: 1,
    height: 1,
  );

  bool get isFullFrame => left == 0 && top == 0 && width == 1 && height == 1;

  double get outputAspect {
    return width == 0 || height == 0 ? 1 : width / height;
  }

  /// Centered crop that produces [targetAspect] from a [sourceAspect] frame.
  ///
  /// Cropping a portrait 9:16 source to 1:1 keeps the full width and cuts the
  /// top and bottom; cropping a landscape source to 9:16 keeps the full height
  /// and cuts the sides. The result always fits inside the source.
  factory VideoCrop.centeredForAspect({
    required double targetAspect,
    required double sourceAspect,
    double inset = 0,
  }) {
    if (targetAspect <= 0 || sourceAspect <= 0) return VideoCrop.original;

    double width = 1;
    double height = 1;

    if (sourceAspect > targetAspect) {
      // Source is wider than the target: crop the sides.
      width = targetAspect / sourceAspect;
    } else if (sourceAspect < targetAspect) {
      // Source is taller: crop top and bottom.
      height = sourceAspect / targetAspect;
    }

    final clampedInset = inset.clamp(0.0, 0.45);
    width *= 1 - clampedInset * 2;
    height *= 1 - clampedInset * 2;

    return VideoCrop(
      left: (1 - width) / 2,
      top: (1 - height) / 2,
      width: width,
      height: height,
    );
  }

  @override
  String toString() =>
      'VideoCrop(${left.toStringAsFixed(3)}, ${top.toStringAsFixed(3)}, '
      '${width.toStringAsFixed(3)}x${height.toStringAsFixed(3)})';

  @override
  bool operator ==(Object other) =>
      other is VideoCrop &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

/// Encoding expectations. The plugin delegates codec choice to Media3 /
/// AVFoundation, so this only controls geometry (plan §14 debt 5).
class VideoOutputSettings {
  /// Longest edge of the exported file; sources smaller than this are never
  /// upscaled.
  final int maxShortEdge;

  const VideoOutputSettings({this.maxShortEdge = 720});

  static const VideoOutputSettings defaults = VideoOutputSettings();

  /// Target export size after [crop], honouring [maxShortEdge] and the encoder
  /// requirement that both dimensions are even.
  ({int width, int height}) targetSize({
    required int sourceWidth,
    required int sourceHeight,
    required VideoCrop crop,
  }) {
    final croppedWidth = math.max(2, (sourceWidth * crop.width).round());
    final croppedHeight = math.max(2, (sourceHeight * crop.height).round());

    final shortEdge = math.min(croppedWidth, croppedHeight);
    final scale = shortEdge > maxShortEdge ? maxShortEdge / shortEdge : 1.0;

    int even(int value) {
      final scaled = (value * scale).round();
      return scaled.isEven ? scaled : scaled - 1;
    }

    return (
      width: math.max(2, even(croppedWidth)),
      height: math.max(2, even(croppedHeight)),
    );
  }
}

/// The exported file plus what we now know about it.
class ProcessedVideo {
  final String path;
  final Duration duration;
  final int width;
  final int height;
  final bool hasAudio;
  final int fileSize;

  /// `false` when the source was already acceptable and was passed through.
  final bool wasReencoded;

  const ProcessedVideo({
    required this.path,
    required this.duration,
    required this.width,
    required this.height,
    required this.hasAudio,
    required this.fileSize,
    this.wasReencoded = true,
  });
}
