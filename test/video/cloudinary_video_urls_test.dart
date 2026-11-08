import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:flutter_test/flutter_test.dart';

const String publicId = 'fashionista/trends/videos/u1/abc-123';

const FeaturedMediaModel videoMedia = FeaturedMediaModel(
  uid: publicId,
  type: 'video',
  url:
      'https://res.cloudinary.com/demo/video/upload/v1712/fashionista/trends/videos/u1/abc-123.mp4',
  thumbnailUrl: 'https://example.invalid/poster.jpg',
  aspectRatio: 9 / 16,
);

void main() {
  group('rendition URLs', () {
    test('SD is a 480p-limited progressive mp4', () {
      final url = CloudinaryVideoUrls.rendition(
        publicId,
        VideoQuality.sd,
        cloudName: 'demo',
      ).toString();

      expect(
        url,
        'https://res.cloudinary.com/demo/video/upload/'
        'c_limit,w_854,h_854,q_auto,vc_h264,f_mp4/$publicId.mp4',
      );
    });

    test('HD is a 720p-limited progressive mp4', () {
      final url = CloudinaryVideoUrls.rendition(
        publicId,
        VideoQuality.hd,
        cloudName: 'demo',
      ).toString();

      expect(
        url,
        'https://res.cloudinary.com/demo/video/upload/'
        'c_limit,w_1280,h_1280,q_auto,vc_h264,f_mp4/$publicId.mp4',
      );
    });

    test('SD and HD are different cache keys', () {
      final sd = CloudinaryVideoUrls.rendition(
        publicId,
        VideoQuality.sd,
        cloudName: 'demo',
      );
      final hd = CloudinaryVideoUrls.rendition(
        publicId,
        VideoQuality.hd,
        cloudName: 'demo',
      );

      expect(sd, isNot(hd));
    });

    test('never relies on f_auto (video_player needs mp4)', () {
      for (final quality in VideoQuality.values) {
        final url = CloudinaryVideoUrls.rendition(
          publicId,
          quality,
          cloudName: 'demo',
        ).toString();

        expect(url, contains('f_mp4'));
        expect(url, isNot(contains('f_auto')));
        expect(url, isNot(contains('c_fill')));
      }
    });

    test('the box matches the quality', () {
      final renditions = CloudinaryVideoUrls.renditions(
        publicId,
        cloudName: 'demo',
      );

      expect(
        renditions.firstWhere((r) => r.quality == VideoQuality.sd).box,
        854,
      );
      expect(
        renditions.firstWhere((r) => r.quality == VideoQuality.hd).box,
        1280,
      );
      expect(renditions, hasLength(2));
    });

    test('poster keeps the first-frame transformation', () {
      expect(
        CloudinaryVideoUrls.poster(publicId, cloudName: 'demo').toString(),
        'https://res.cloudinary.com/demo/video/upload/'
        'so_0,w_720,q_auto/$publicId.jpg',
      );
    });

    test('a stored .mp4 extension is not doubled', () {
      final url = CloudinaryVideoUrls.rendition(
        '$publicId.mp4',
        VideoQuality.sd,
        cloudName: 'demo',
      ).toString();

      expect(url, endsWith('/$publicId.mp4'));
      expect(url, isNot(contains('.mp4.mp4')));
    });
  });

  group('publicIdOf', () {
    test('uses the stored uid', () {
      expect(CloudinaryVideoUrls.publicIdOf(videoMedia), publicId);
    });

    test('falls back to parsing the delivery URL', () {
      const media = FeaturedMediaModel(
        type: 'video',
        url:
            'https://res.cloudinary.com/demo/video/upload/'
            'v1712345678/fashionista/trends/videos/u1/xyz.mp4',
      );

      expect(
        CloudinaryVideoUrls.publicIdOf(media),
        'fashionista/trends/videos/u1/xyz',
      );
    });

    test('ignores image posts', () {
      const image = FeaturedMediaModel(
        uid: 'fashionista/banner/u1',
        type: 'image',
        url: 'https://example.invalid/a.jpg',
      );

      expect(CloudinaryVideoUrls.publicIdOf(image), isNull);
    });

    test('returns null when nothing can be derived', () {
      const media = FeaturedMediaModel(type: 'video', url: 'not a url');

      expect(CloudinaryVideoUrls.publicIdOf(media), isNull);
    });
  });

  group('VideoQuality', () {
    test('labels and the toggle target', () {
      expect(VideoQuality.sd.label, 'SD');
      expect(VideoQuality.hd.label, 'HD');
      expect(VideoQuality.sd.other, VideoQuality.hd);
      expect(VideoQuality.hd.other, VideoQuality.sd);
    });
  });
}
