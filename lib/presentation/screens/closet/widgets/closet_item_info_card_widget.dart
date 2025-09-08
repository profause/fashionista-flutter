import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ClosetItemInfoCardWidget extends StatefulWidget {
  final ClosetItemModel closetItem;
  final VoidCallback? onPress;
  const ClosetItemInfoCardWidget({
    super.key,
    required this.closetItem,
    this.onPress,
  });

  @override
  State<ClosetItemInfoCardWidget> createState() =>
      _ClosetItemInfoCardWidgetState();
}

class _ClosetItemInfoCardWidgetState extends State<ClosetItemInfoCardWidget>
    with SingleTickerProviderStateMixin {
  late bool isFavourite;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    setState(() {
      isFavourite = widget.closetItem.isFavourite ?? false;
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
    final FeaturedMediaModel featuredMedia =
        widget.closetItem.featuredMedia.isNotEmpty
        ? widget.closetItem.featuredMedia.first
        : FeaturedMediaModel();

    return Container(
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
      child: GestureDetector(
        onTap: () => widget.onPress?.call(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: featuredMedia.aspectRatio ?? 1 / 1,
                  child: CachedNetworkImage(
                    imageUrl: featuredMedia.url ?? '',
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
                    errorListener: (value) {
                      
                    },
                  ),
                ),

                Positioned(
                  right: 6,
                  bottom: 8,
                  child: CustomIconButtonRounded(
                    iconData: Icons.favorite_outline,
                    size: 18,
                    onPressed: () =>
                        addOrRemoveFromFavourite(widget.closetItem.uid!),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_outline,
                        key: ValueKey(isFavourite),
                        color: isFavourite ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ✅ Let this part flex to fit inside grid item
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 4,
                  top: 4,
                  bottom: 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.closetItem.description,
                            style: textTheme.bodyMedium!.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.closetItem.category,
                            style: textTheme.bodySmall!.copyWith(
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addOrRemoveFromFavourite(String closetId) async {
    try {
      final result = await sl<FirebaseClosetService>()
          .addOrRemoveFavouriteClosetItem(closetId);
      result.fold(
        (l) => debugPrint("Error adding or removing favourite closet item: $l"),
        (r) {
          setState(() {
            isFavourite = r;
          });
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
