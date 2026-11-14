import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Saves the first media item of a trend to the device gallery.
class TrendMediaDownloadService {
  final Dio _dio;

  TrendMediaDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Either<String, Unit>> download(TrendFeedModel trend) async {
    if (trend.featuredMedia.isEmpty) {
      return const Left('This trend has no media to download.');
    }

    final media = trend.featuredMedia.first;
    final url = _downloadUrl(media);
    if (url == null || url.isEmpty) {
      return const Left('This media could not be prepared for download.');
    }

    String? path;
    try {
      final directory = await getTemporaryDirectory();
      final extension = _extensionFor(media, url);
      final rawId = trend.uid ?? '${DateTime.now().microsecondsSinceEpoch}';
      final safeId = rawId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      path =
          '${directory.path}/fashionista_trend_${safeId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _dio.download(url, path);

      final access = await Gal.hasAccess();
      if (!access && !await Gal.requestAccess()) {
        return const Left('Gallery permission is needed to save this media.');
      }

      if (media.isVideo) {
        await Gal.putVideo(path);
      } else {
        await Gal.putImage(path);
      }

      return const Right(unit);
    } on GalException catch (e) {
      return Left(_galMessage(e.type));
    } on DioException catch (e) {
      return Left(
        e.message == null
            ? 'Could not download this media. Please try again.'
            : 'Could not download this media: ${e.message}',
      );
    } catch (e) {
      return Left('Could not save this media: $e');
    } finally {
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // A leftover temp file is harmless; the OS sweeps the cache.
        }
      }
    }
  }

  String? _downloadUrl(FeaturedMediaModel media) {
    if (media.isVideo) {
      final publicId = CloudinaryVideoUrls.publicIdOf(media);
      if (publicId != null) {
        return CloudinaryVideoUrls.rendition(
          publicId,
          VideoQuality.hd,
        ).toString();
      }
      return media.url;
    }

    final storedUrl = media.url?.trim();
    if (storedUrl != null && storedUrl.isNotEmpty) return storedUrl;

    final cloudName = CloudinaryVideoUrls.resolveCloudName();
    final publicId = media.uid;
    if (cloudName.isEmpty || publicId == null || publicId.isEmpty) return null;

    final encodedId = publicId.split('/').map(Uri.encodeComponent).join('/');
    return 'https://res.cloudinary.com/$cloudName/image/upload/'
        'q_auto:eco/$encodedId.jpg';
  }

  String _extensionFor(FeaturedMediaModel media, String url) {
    if (media.isVideo) return 'mp4';

    final declared = media.format?.toLowerCase().trim();
    if (declared != null && declared.isNotEmpty) return declared;

    final uri = Uri.tryParse(url);
    final pathExtension = uri == null || uri.pathSegments.isEmpty
        ? ''
        : uri.pathSegments.last.split('.').last.toLowerCase();
    const supported = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
    return supported.contains(pathExtension) ? pathExtension : 'jpg';
  }

  String _galMessage(GalExceptionType type) {
    switch (type) {
      case GalExceptionType.accessDenied:
        return 'Gallery permission is needed to save this media.';
      case GalExceptionType.notEnoughSpace:
        return 'There is not enough storage space to save this media.';
      case GalExceptionType.notSupportedFormat:
        return 'This media format cannot be saved to your gallery.';
      case GalExceptionType.unexpected:
        return 'Could not save this media. Please try again.';
    }
  }
}
