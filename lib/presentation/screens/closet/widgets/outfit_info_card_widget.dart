
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class OutfitInfoCardWidget extends StatefulWidget {
  final OutfitModel outfitModel;
  final VoidCallback? onPress;
  const OutfitInfoCardWidget({
    super.key,
    required this.outfitModel,
    this.onPress,
  });

  @override
  State<OutfitInfoCardWidget> createState() => _OutfitInfoCardWidgetState();
}

class _OutfitInfoCardWidgetState extends State<OutfitInfoCardWidget>
    with SingleTickerProviderStateMixin {
  late bool isFavourite;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    setState(() {
      isFavourite = widget.outfitModel.isFavourite ?? false;
      //debugPrint('isFavourite: $isFavourite');
      if (!mounted) return;
      _controller.forward(from: 0);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    List<FeaturedMediaModel> featuredMedia = widget.outfitModel.closetItems.map(
      (item) {
        return item.featuredMedia.first;
      },
    ).toList();

    final thumbnailUrl = widget.outfitModel.thumbnailUrl ?? '';

    if (thumbnailUrl.isNotEmpty) {
      featuredMedia = [
        FeaturedMediaModel(
          url: thumbnailUrl,
          type: "image", // 👈 or whatever field your model uses
        ),
      ];
    }

    return GestureDetector(
      onTap: () => widget.onPress?.call(),
      child: Container(
        margin: const EdgeInsets.all(0),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MasonryGridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap:
                    true, // ✅ important when inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // ✅ let parent handle scroll
                cacheExtent: 10,
                // ✅ adapt crossAxisCount based on item count
                gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: featuredMedia.length == 1
                      ? 1 // 1 item -> full width
                      : featuredMedia.length <= 4
                      ? 2 // 2–4 items -> 2 columns
                      : 3, // 5+ items -> 3 columns
                ),
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                itemCount: featuredMedia.length,
                itemBuilder: (context, index) {
                  final preview = featuredMedia[index];
                  // 👇 Assign different aspect ratios randomly for variety
                  // ✅ aspect ratio adapts too
                  // double aspectRatio;
                  // if (featuredMedia.length == 1) {
                  //   aspectRatio = 3 / 2; // square full width
                  // } else if (featuredMedia.length == 2) {
                  //   aspectRatio = 4 / 5; // taller
                  // } else {
                  //   // variety for larger grids
                  //   final aspectRatioOptions = [1 / 1, 3 / 4, 3 / 1];
                  //   aspectRatio =
                  //       aspectRatioOptions[Random().nextInt(
                  //         aspectRatioOptions.length,
                  //       )];
                  // }
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CachedNetworkImage(
                        imageUrl: preview.url!.isEmpty
                            ? ''
                            : preview.url!.trim(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          return const CustomColoredBanner(text: '');
                        },
                        errorListener: (value) {},
                      ),
                    
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.outfitModel.style ?? '',
                          style: textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CustomIconButtonRounded(
                        iconData: Icons.favorite_outline,
                        size: 18,
                        onPressed: () =>
                            addOrRemoveFromFavourite(widget.outfitModel.uid!),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            key: ValueKey(isFavourite),
                            color: isFavourite ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.outfitModel.occassion,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addOrRemoveFromFavourite(String outfitId) async {
    try {
      final result = await sl<FirebaseClosetService>()
          .addOrRemoveFavouriteOutfit(outfitId);
      result.fold(
        (l) => debugPrint("Error adding or removing favourite outfit: $l"),
        (r) {
          setState(() {
            isFavourite = r;
          });

          context.read<ClosetOutfitBloc>().add(
            const LoadOutfitsCacheFirstThenNetwork(''),
          );
        },
      );
    } on FirebaseException catch (e) {
      debugPrint(
        "Error adding or removing favourite closet item: ${e.message}",
      );
      //return Left(e.message);
    }
  }
}
