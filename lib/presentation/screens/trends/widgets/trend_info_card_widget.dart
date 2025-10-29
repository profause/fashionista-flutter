import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/video_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TrendInfoCardWidget extends StatelessWidget {
  final TrendFeedModel trendInfo;
  final double aspectRatio;

  const TrendInfoCardWidget({
    super.key,
    required this.trendInfo,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // ✅ Safe check for empty media list
    final FeaturedMediaModel? featuredMedia = trendInfo.featuredMedia.isNotEmpty
        ? trendInfo.featuredMedia.first
        : null;

    final isVideo =
        featuredMedia != null && featuredMedia.type?.toLowerCase() == 'video';

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => context.push('/trends/${trendInfo.uid}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: featuredMedia?.aspectRatio ?? aspectRatio,
                  child: _buildMediaContent(featuredMedia, isVideo),
                ),

                // --- Profile Avatar (top-left) ---
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    key: ValueKey(trendInfo.author.uid),
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: CachedNetworkImage(
                        imageUrl: trendInfo.author.avatar!,
                        errorListener: (error) {},
                        placeholder: (context, url) => DefaultProfileAvatar(
                          key: ValueKey(trendInfo.author.uid),
                          name: null,
                          size: 18 * 1.8,
                          uid: trendInfo.author.uid!,
                        ),
                        errorWidget: (context, url, error) =>
                            DefaultProfileAvatar(
                              key: ValueKey(trendInfo.author.uid),
                              name: null,
                              size: 18 * 1.8,
                              uid: trendInfo.author.uid!,
                            ),
                      ),
                    ),
                  ),
                ),

                // --- Description banner (bottom) ---
                if (trendInfo.description.isNotEmpty)
                  Positioned(
                    right: 4,
                    bottom: 8,
                    left: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          trendInfo.description,
                          style: textTheme.bodySmall!.copyWith(
                            color: colorScheme.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 👇 Extracted media builder with placeholder
  Widget _buildMediaContent(FeaturedMediaModel? media, bool isVideo) {
    if (media == null) {
      // 🩶 Show a grey placeholder when there's no image/video
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 36,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (isVideo) {
      return VideoPreviewWidget(videoUrl: media.url!, onTap: () {});
    }

    return CachedNetworkImage(
      imageUrl: media.url!.trim(),
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}
