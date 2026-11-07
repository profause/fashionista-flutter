import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';

/// Parameters Cloudinary needs echoed back, signed by the backend.
class VideoUploadSignature extends Equatable {
  final String cloudName;
  final String apiKey;
  final int timestamp;
  final String signature;
  final String folder;
  final String publicId;

  const VideoUploadSignature({
    required this.cloudName,
    required this.apiKey,
    required this.timestamp,
    required this.signature,
    required this.folder,
    required this.publicId,
  });

  factory VideoUploadSignature.fromMap(Map<dynamic, dynamic> map) {
    return VideoUploadSignature(
      cloudName: '${map['cloudName'] ?? ''}',
      apiKey: '${map['apiKey'] ?? ''}',
      timestamp: int.tryParse('${map['timestamp'] ?? ''}') ?? 0,
      signature: '${map['signature'] ?? ''}',
      folder: '${map['folder'] ?? ''}',
      publicId: '${map['publicId'] ?? ''}',
    );
  }

  bool get isComplete =>
      cloudName.isNotEmpty &&
      apiKey.isNotEmpty &&
      signature.isNotEmpty &&
      folder.isNotEmpty &&
      publicId.isNotEmpty &&
      timestamp > 0;

  @override
  List<Object?> get props => [
    cloudName,
    apiKey,
    timestamp,
    signature,
    folder,
    publicId,
  ];
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

  const CloudinaryVideoAsset({
    required this.assetId,
    required this.secureUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.fileSize,
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
    );
  }

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
  ];
}
