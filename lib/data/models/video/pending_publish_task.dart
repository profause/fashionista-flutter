import 'package:fashionista/data/models/featured_media/featured_media_model.dart';

/// A video that reached Cloudinary but whose trend document was never written.
///
/// Persisted so the publish step can be retried without uploading again
/// (plan §6.5). The asset already exists, so dropping this record would leak it.
class PendingPublishTask {
  final String trendId;
  final FeaturedMediaModel media;
  final DateTime createdAt;

  const PendingPublishTask({
    required this.trendId,
    required this.media,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'trend_id': trendId,
    'media': media.toJson(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  static PendingPublishTask? fromJson(Map<String, dynamic> json) {
    final trendId = json['trend_id'];
    final media = json['media'];
    if (trendId is! String || media is! Map) return null;

    return PendingPublishTask(
      trendId: trendId,
      media: FeaturedMediaModel.fromJson(Map<String, dynamic>.from(media)),
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}
