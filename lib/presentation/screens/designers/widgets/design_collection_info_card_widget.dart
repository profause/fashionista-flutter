import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/presentation/widgets/custom_bookmark_design_collection_icon_button.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';

class DesignCollectionInfoCardWidget extends StatelessWidget {
  final DesignCollectionModel designCollectionInfo;
  final double aspectRatio; // 👈 new parameter

  const DesignCollectionInfoCardWidget({
    super.key,
    required this.designCollectionInfo,
    this.aspectRatio = 16 / 9,// default ratio
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image Section with avatar overlay ---
          Stack(
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: CachedNetworkImage(
                  imageUrl: designCollectionInfo.featuredImages.first.trim(),
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
                      child: designCollectionInfo.author.avatar!.isNotEmpty
                          ? CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.lightGrey,
                              backgroundImage: CachedNetworkImageProvider(
                                designCollectionInfo.author.avatar!,
                              ),
                            )
                          : DefaultProfileAvatar(
                              name: null,
                              size: 18 * 1.8,
                              uid: designCollectionInfo.author.uid!,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- Title Section ---
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    designCollectionInfo.title,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CustomBookmarkDesignCollectionIconButton(
                  designerCollectionId: designCollectionInfo.uid!,
                  isBookmarkedNotifier: ValueNotifier(
                    designCollectionInfo.isBookmarked!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
