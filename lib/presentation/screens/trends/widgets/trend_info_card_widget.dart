import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/presentation/screens/trends/trend_details_screen.dart';
import 'package:fashionista/presentation/screens/trends/widgets/custom_trend_like_button_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/video_preview_widget.dart';
import 'package:flutter/material.dart';

class TrendInfoCardWidget extends StatelessWidget {
  final TrendFeedModel trendInfo;
  final double aspectRatio; // 👈 new parameter

  const TrendInfoCardWidget({
    super.key,
    required this.trendInfo,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final FeaturedMediaModel featuredMedia = trendInfo.featuredMedia.first;
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
        onTap: () {
          // Example: Navigate to Designer Details Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TrendDetailsScreen(trendInfo: trendInfo, initialIndex: 0),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: featuredMedia.type!.toLowerCase() == 'video'
                      ? 9 / 16
                      : aspectRatio,
                  child: featuredMedia.type!.toLowerCase() == 'video'
                      ? VideoPreviewWidget(
                          videoUrl: trendInfo.featuredMedia.first.url!,
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => FullVideoScreen(
                            //       videoUrl: trend.featuredMedia.url,
                            //     ),
                            //   ),
                            // );
                          },
                        )
                      : CachedNetworkImage(
                          imageUrl: trendInfo.featuredMedia.isEmpty
                              ? ''
                              : featuredMedia.url!.trim(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return const CustomColoredBanner(text: 'No Image');
                          },
                        ),
                ),
                // --- Profile Avatar (top-left) ---
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.white,
                    borderOnForeground: true,
                    borderRadius: BorderRadius.circular(60),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {},
                        child: trendInfo.author.avatar!.isNotEmpty
                            ? CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.lightGrey,
                                backgroundImage: CachedNetworkImageProvider(
                                  trendInfo.author.avatar!,
                                ),
                              )
                            : DefaultProfileAvatar(
                                name: null,
                                size: 18 * 1.8,
                                uid: trendInfo.author.uid!,
                              ),
                      ),
                    ),
                  ),
                ),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              trendInfo.description,
                              style: textTheme.bodySmall!.copyWith(
                                color: colorScheme.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CustomTrendLikeButtonWidget(
                            trendId: trendInfo.uid!,
                            isLikedNotifier: ValueNotifier(
                              LikeObject(
                                count: trendInfo.numberOfLikes == null
                                    ? 0
                                    : trendInfo.numberOfLikes!,
                                isLiked: trendInfo.isLiked!,
                              ),
                            ),
                          ),
                        ],
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
}
