import 'package:fashionista/data/models/video/edited_video.dart';
import 'package:fashionista/data/models/video/video_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoCrop.centeredForAspect', () {
    test('keeps the full width when cropping a tall source to 1:1', () {
      // 9:16 source (0.5625) to square: crop the top and bottom.
      final crop = VideoCrop.centeredForAspect(
        targetAspect: 1,
        sourceAspect: 9 / 16,
      );

      expect(crop.width, 1);
      expect(crop.height, closeTo(9 / 16, 1e-9));
      expect(crop.top, closeTo((1 - 9 / 16) / 2, 1e-9));
      expect(crop.left, 0);
    });

    test('keeps the full height when cropping a wide source to 9:16', () {
      // 16:9 source (1.777) to 9:16 (0.5625): crop the sides.
      final crop = VideoCrop.centeredForAspect(
        targetAspect: 9 / 16,
        sourceAspect: 16 / 9,
      );

      expect(crop.height, 1);
      expect(crop.width, closeTo((9 / 16) / (16 / 9), 1e-9));
      expect(crop.left, closeTo((1 - crop.width) / 2, 1e-9));
      expect(crop.top, 0);
    });

    test('is a no-op when the source already matches', () {
      final crop = VideoCrop.centeredForAspect(
        targetAspect: 4 / 5,
        sourceAspect: 4 / 5,
      );

      expect(crop.isFullFrame, isTrue);
    });

    test('never leaves the source frame', () {
      for (final source in [0.4, 0.5625, 1.0, 1.333, 1.777, 2.4]) {
        for (final target in [0.5625, 0.8, 1.0]) {
          final crop = VideoCrop.centeredForAspect(
            targetAspect: target,
            sourceAspect: source,
          );

          expect(crop.left, greaterThanOrEqualTo(0));
          expect(crop.top, greaterThanOrEqualTo(0));
          expect(crop.width, lessThanOrEqualTo(1));
          expect(crop.height, lessThanOrEqualTo(1));
          expect(crop.left + crop.width, lessThanOrEqualTo(1.0000001));
          expect(crop.top + crop.height, lessThanOrEqualTo(1.0000001));
        }
      }
    });

    test('the cropped frame carries the requested aspect', () {
      const sourceAspect = 9 / 16;
      const targetAspect = 4 / 5;
      final crop = VideoCrop.centeredForAspect(
        targetAspect: targetAspect,
        sourceAspect: sourceAspect,
      );

      // On-screen aspect of the crop = source aspect × (width / height).
      expect(sourceAspect * crop.outputAspect, closeTo(targetAspect, 1e-9));
    });

    test('ignores invalid input instead of producing NaN', () {
      expect(
        VideoCrop.centeredForAspect(
          targetAspect: 0,
          sourceAspect: 1,
        ).isFullFrame,
        isTrue,
      );
      expect(
        VideoCrop.centeredForAspect(
          targetAspect: 1,
          sourceAspect: 0,
        ).isFullFrame,
        isTrue,
      );
    });
  });

  group('VideoOutputSettings.targetSize', () {
    test('caps the short edge at 720 and keeps dimensions even', () {
      final size = VideoOutputSettings.defaults.targetSize(
        sourceWidth: 1920,
        sourceHeight: 1080,
        crop: VideoCrop.original,
      );

      expect(size.height, 720);
      expect(size.width, 1280);
      expect(size.width.isEven, isTrue);
      expect(size.height.isEven, isTrue);
    });

    test('never upscales a small source', () {
      final size = VideoOutputSettings.defaults.targetSize(
        sourceWidth: 480,
        sourceHeight: 854,
        crop: VideoCrop.original,
      );

      expect(size.width, 480);
      expect(size.height, 854);
    });

    test('sizes the export from the cropped region, not the source', () {
      final crop = VideoCrop.centeredForAspect(
        targetAspect: 1,
        sourceAspect: 9 / 16,
      );

      final size = VideoOutputSettings.defaults.targetSize(
        sourceWidth: 1080,
        sourceHeight: 1920,
        crop: crop,
      );

      expect(size.width, 720);
      expect(size.height, 720);
    });

    test('odd results are reduced by one pixel', () {
      final size = VideoOutputSettings.defaults.targetSize(
        sourceWidth: 721,
        sourceHeight: 1281,
        crop: VideoCrop.original,
      );

      expect(size.width.isEven, isTrue);
      expect(size.height.isEven, isTrue);
    });
  });

  group('EditedVideo', () {
    test('formats its size for the composer', () {
      const video = EditedVideo(
        path: '/tmp/a.mp4',
        duration: Duration(seconds: 12),
        width: 720,
        height: 1280,
        hasAudio: false,
        fileSize: 4509715,
      );

      expect(video.sizeLabel, '4.3 MB');
      expect(video.aspectRatio, 720 / 1280);
    });
  });
}
