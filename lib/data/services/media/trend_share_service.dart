import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a trend caption and its first media URL through the native sheet.
class TrendShareService {
  Future<Either<String, Unit>> shareTrend(
    TrendFeedModel trend, {
    Rect? sharePositionOrigin,
  }) async {
    final media = trend.featuredMedia.isEmpty
        ? null
        : trend.featuredMedia.first;

    String? mediaUrl;
    if (media != null) {
      if (media.isVideo) {
        final publicId = CloudinaryVideoUrls.publicIdOf(media);
        mediaUrl = publicId == null
            ? media.url
            : CloudinaryVideoUrls.rendition(
                publicId,
                VideoQuality.hd,
              ).toString();
      } else {
        mediaUrl = media.url;
      }
    }

    final parts = <String>[
      if (trend.description.trim().isNotEmpty) trend.description.trim(),
      if (mediaUrl != null && mediaUrl.trim().isNotEmpty) mediaUrl.trim(),
    ];

    if (parts.isEmpty) {
      return const Left('There is nothing to share from this trend.');
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: parts.join('\n\n'),
          subject: 'Fashionista trend',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left('Could not open the share sheet: $e');
    }
  }
}
