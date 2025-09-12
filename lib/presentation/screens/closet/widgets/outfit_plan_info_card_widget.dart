import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class OutfitPlanInfoCardWidget extends StatelessWidget {
  final OutfitPlanModel plan;
  final VoidCallback? onTap;

  const OutfitPlanInfoCardWidget({super.key, required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<FeaturedMediaModel> featuredMedia =
        plan.outfitItem.featuredMedia;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: featuredMedia.length > 4 ? 3 : 2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: featuredMedia.length,
          itemBuilder: (context, index) {
            final preview = featuredMedia[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: preview.url?.trim() ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    const CustomColoredBanner(text: ''),
              ),
            );
          },
        ),
      ),

      // Text(plan.occassion ?? ""),
    );
  }
}
