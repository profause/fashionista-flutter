import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_flutter/image/cld_image_widget_configuration.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/theme/app.theme.dart';
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
    final textTheme = Theme.of(context).textTheme;

    // ✅ Safe check for empty media list
    final FeaturedMediaModel? featuredMedia = trendInfo.featuredMedia.isNotEmpty
        ? trendInfo.featuredMedia.first
        : null;

    final isVideo =
        featuredMedia != null && featuredMedia.type?.toLowerCase() == 'video';
    final mediaAspectRatio = featuredMedia?.aspectRatio ?? aspectRatio;

    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
                  aspectRatio: mediaAspectRatio,
                  child: _buildMediaContent(
                    featuredMedia,
                    isVideo,
                    mediaAspectRatio,
                  ),
                ),

                // --- Profile Avatar (top-left) ---
                Positioned(
                  top: 10,
                  left: 10,
                  child: CircleAvatar(
                    key: ValueKey(trendInfo.author.uid),
                    radius: 15,
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
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

                    Positioned(
                      top: 14,
                      left: 50,
                      right: 8,
                      child: Text(
                        '@${trendInfo.author.name ?? 'fashionista'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),

                // --- Description banner (bottom) ---
                if (trendInfo.description.isNotEmpty)
                  Positioned(
                        right: 0,
                        bottom: 0,
                        left: 0,
                    child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 26, 10, 10),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xE6000000),
                              ],
                            ),
                      ),
                          child: Text(
                            trendInfo.description,
                            style: textTheme.bodyMedium!.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.2,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
  Widget _buildMediaContent(
    FeaturedMediaModel? media,
    bool isVideo,
    double aspectRatio,
  ) {
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

    return CldImageWidget(
      key: ValueKey(media.uid),
      cloudinary: Cloudinary.fromConfiguration(
        CloudinaryConfig.fromUri(appConfig.get('cloudinary_url')),
      ),
      publicId: '${media.uid}',
      configuration: CldImageWidgetConfiguration(cache: true),
      placeholder: (context, url) => const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      placeholderFadeInDuration: const Duration(milliseconds: 150),
      errorBuilder: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
      transformation: Transformation().addTransformation('q_auto:eco')
        ..resize(Resize.fill().aspectRatio(aspectRatio)),
    );

    // CachedNetworkImage(
    //   imageUrl: media.url!.trim(),
    //   fit: BoxFit.cover,
    //   placeholder: (context, url) => const Center(
    //     child: SizedBox(
    //       height: 18,
    //       width: 18,
    //       child: CircularProgressIndicator(strokeWidth: 2),
    //     ),
    //   ),
    //   errorWidget: (context, url, error) => Container(
    //     color: Colors.grey[300],
    //     child: const Center(
    //       child: Icon(Icons.broken_image, color: Colors.grey),
    //     ),
    //   ),
    // );
  }
}
