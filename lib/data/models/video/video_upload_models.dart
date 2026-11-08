import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';

/// Cloudinary parameters for an *unsigned* video upload.
///
/// There is no API key, timestamp or signature any more: the upload is
/// authorized by the (public) upload preset alone, so nothing here is secret.
/// See `.agents/plans/trends-video.md` §19.
class VideoUploadConfig extends Equatable {
  final String cloudName;
  final String uploadPreset;

  /// Base folder every video lives under; the user id is appended per upload so
  /// assets stay attributable. Mirrors `trendVideoFolder()` in
  /// `functions/src/cloudinary/folder.ts` and the `CLOUDINARY_BASE_FOLDER` env
  /// var used by the delete callable.
  final String baseFolder;

  const VideoUploadConfig({
    required this.cloudName,
    required this.uploadPreset,
    required this.baseFolder,
  });

  bool get isComplete =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty && baseFolder.isNotEmpty;

  /// `<baseFolder>/trends/videos/<uid>` — the folder this user's videos are
  /// written to.
  String folderFor(String userId) {
    final base = baseFolder.endsWith('/')
        ? baseFolder.substring(0, baseFolder.length - 1)
        : baseFolder;
    return '$base/trends/videos/$userId';
  }

  @override
  List<Object?> get props => [cloudName, uploadPreset, baseFolder];
}

/// The uploaded Cloudinary asset, normalised into what a trend post stores.
class CloudinaryVideoAsset extends Equatable {
  /// Full Cloudinary public id, folder included.
  final String assetId;
  final String secureUrl;
  final String thumbnailUrl;
  final double durationSeconds;
  final int width;
  final int height;
  final int fileSize;

  /// Short-lived (10 min) credential returned by the upload preset. Kept on the
  /// device only — it grants deletion, so it must never reach Firestore.
  final String? deleteToken;

  const CloudinaryVideoAsset({
    required this.assetId,
    required this.secureUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.fileSize,
    this.deleteToken,
  });

  /// Builds the poster URL from the video itself — no second upload (plan §8,
  /// milestone 4).
  factory CloudinaryVideoAsset.fromResponse(
    Map<String, dynamic> data, {
    required String cloudName,
    required String fallbackPublicId,
  }) {
    final assetId = '${data['public_id'] ?? fallbackPublicId}';
    final secureUrl = '${data['secure_url'] ?? ''}';
    final token = data['delete_token'];

    return CloudinaryVideoAsset(
      assetId: assetId,
      secureUrl: secureUrl,
      thumbnailUrl:
          'https://res.cloudinary.com/$cloudName/video/upload/'
          'so_0,w_720,q_auto/$assetId.jpg',
      durationSeconds: _toDouble(data['duration']),
      width: (data['width'] as num?)?.toInt() ?? 0,
      height: (data['height'] as num?)?.toInt() ?? 0,
      fileSize: (data['bytes'] as num?)?.toInt() ?? 0,
      deleteToken: token is String && token.isNotEmpty ? token : null,
    );
  }

  bool get hasDeleteToken => deleteToken != null;

  /// Feed media entry for this asset.
  FeaturedMediaModel toMedia({required bool hasAudio}) {
    return FeaturedMediaModel(
      uid: assetId,
      type: 'video',
      url: secureUrl,
      thumbnailUrl: thumbnailUrl,
      aspectRatio: height == 0 ? 9 / 16 : width / height,
      duration: durationSeconds,
      width: width,
      height: height,
      hasAudio: hasAudio,
      format: 'mp4',
      fileSize: fileSize,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}') ?? 0;
  }

  @override
  List<Object?> get props => [
    assetId,
    secureUrl,
    thumbnailUrl,
    durationSeconds,
    width,
    height,
    fileSize,
    deleteToken,
  ];
}
