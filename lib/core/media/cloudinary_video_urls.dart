import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:flutter/foundation.dart';

/// Delivery quality of a Trends video.
///
/// Every video starts in [sd]; [hd] is only ever requested by an explicit user
/// action on the card being watched (plan §5).
enum VideoQuality {
  sd('SD'),
  hd('HD');

  const VideoQuality(this.label);

  final String label;

  VideoQuality get other =>
      this == VideoQuality.sd ? VideoQuality.hd : VideoQuality.sd;
}

/// One deliverable rendition of a Cloudinary video.
class VideoRendition {
  final VideoQuality quality;
  final Uri url;

  /// Longest edge of the bounding box the rendition is scaled into.
  final int box;

  const VideoRendition({
    required this.quality,
    required this.url,
    required this.box,
  });

  @override
  String toString() => 'VideoRendition(${quality.label}, $url)';
}

/// Builds Cloudinary delivery URLs for Trends videos.
///
/// Only the original asset is stored; renditions are transformations of the
/// same public id, so the SD and HD URLs differ and therefore cache separately.
/// Both pin `f_mp4` + `vc_h264`: `video_player` needs a progressive MP4, and
/// `f_auto` could hand back HLS/WebM.
class CloudinaryVideoUrls {
  CloudinaryVideoUrls._();

  /// 480p bounding box (854 is the long edge of 480p at 16:9).
  static const int sdBox = 854;

  /// 720p bounding box (1280 is the long edge of 720p at 16:9).
  static const int hdBox = 1280;

  static String? _cloudName;

  /// Cloud name from `cloudinary_url` (`cloudinary://key:secret@<cloud>`).
  ///
  /// Only the host is read, so the credentials never leave the config. Cached
  /// once resolved because Remote Config lookups are not free.
  static String resolveCloudName({String? override}) {
    if (override != null && override.isNotEmpty) return override;
    final cached = _cloudName;
    if (cached != null) return cached;

    try {
      final host = Uri.tryParse('${appConfig.get('cloudinary_url')}')?.host;
      if (host != null && host.isNotEmpty) {
        _cloudName = host;
        return host;
      }
    } catch (error) {
      debugPrint('Cloudinary cloud name unavailable: $error');
    }

    return '';
  }

  /// Poster frame used by feed cards (`so_0` = first frame).
  static Uri poster(String publicId, {String? cloudName}) {
    final cloud = resolveCloudName(override: cloudName);
    return Uri.parse(
      'https://res.cloudinary.com/$cloud/video/upload/'
      'so_0,w_720,q_auto/${_cleanId(publicId)}.jpg',
    );
  }

  /// Delivery URL of [quality] for [publicId].
  static Uri rendition(
    String publicId,
    VideoQuality quality, {
    String? cloudName,
  }) {
    final cloud = resolveCloudName(override: cloudName);
    final box = quality == VideoQuality.hd ? hdBox : sdBox;

    // c_limit fits inside the box, keeps the aspect ratio and never upscales.
    return Uri.parse(
      'https://res.cloudinary.com/$cloud/video/upload/'
      'c_limit,w_$box,h_$box,q_auto,vc_h264,f_mp4/${_cleanId(publicId)}.mp4',
    );
  }

  static List<VideoRendition> renditions(String publicId, {String? cloudName}) {
    return [
      for (final quality in VideoQuality.values)
        VideoRendition(
          quality: quality,
          url: rendition(publicId, quality, cloudName: cloudName),
          box: quality == VideoQuality.hd ? hdBox : sdBox,
        ),
    ];
  }

  /// Cloudinary public id of a video post, or `null` when it cannot be derived.
  ///
  /// `FeaturedMediaModel.uid` already holds it for posts created by the app;
  /// older or hand-made documents fall back to parsing `url`.
  static String? publicIdOf(FeaturedMediaModel media) {
    if (!media.isVideo) return null;

    final uid = media.uid?.trim() ?? '';
    if (uid.isNotEmpty && !uid.startsWith('http')) return _cleanId(uid);

    return _publicIdFromUrl(media.url);
  }

  static String? _publicIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final marker = uri.pathSegments.indexOf('upload');
    if (marker < 0 || marker + 1 >= uri.pathSegments.length) return null;

    final segments = uri.pathSegments.sublist(marker + 1);
    // Drop the version segment (`v1712345678`) when present.
    if (segments.isNotEmpty && RegExp(r'^v\d+$').hasMatch(segments.first)) {
      segments.removeAt(0);
    }
    if (segments.isEmpty) return null;

    return _cleanId(segments.join('/'));
  }

  /// Public ids carry no extension; a stored `.mp4` would double up.
  static String _cleanId(String publicId) {
    final trimmed = publicId.trim();
    return trimmed.toLowerCase().endsWith('.mp4')
        ? trimmed.substring(0, trimmed.length - 4)
        : trimmed;
  }
}
