import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_event.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClosetItemInfoCardWidget extends StatefulWidget {
  final ClosetItemModel closetItem;
  final VoidCallback? onPress;
  final VoidCallback? onSelect;
  const ClosetItemInfoCardWidget({
    super.key,
    required this.closetItem,
    this.onPress,
    this.onSelect,
  });

  @override
  State<ClosetItemInfoCardWidget> createState() =>
      _ClosetItemInfoCardWidgetState();
}

class _ClosetItemInfoCardWidgetState extends State<ClosetItemInfoCardWidget>
    with SingleTickerProviderStateMixin {
  late bool isFavourite;
  late bool isSelected;
  late AnimationController _controller;
  late ClosetItemModel closetItemModel;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    closetItemModel = widget.closetItem;
    isFavourite = widget.closetItem.isFavourite ?? false;
    isSelected = widget.closetItem.isSelected ?? false;
    if (!mounted) return;
    _controller.forward(from: 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final FeaturedMediaModel featuredMedia =
        widget.closetItem.featuredMedia.isNotEmpty
        ? widget.closetItem.featuredMedia.first
        : FeaturedMediaModel();

    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected = !isSelected;
          closetItemModel = widget.closetItem.copyWith(isSelected: isSelected);
        });
        widget.onPress == null
            ? widget.onSelect?.call()
            : widget.onPress?.call();
      },
      child: Container(
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.hairline),
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
                    errorListener: (value) {},
                  ),
                ),

                // ✅ Animated overlay
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () =>
                        addOrRemoveFromFavourite(widget.closetItem.uid!),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.isDarkTheme
                            ? context.secondaryButtonBg
                            : Colors.white.withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            key: ValueKey(isFavourite),
                            color: isFavourite
                                ? context.accent
                                : context.secondaryLabel,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ✅ Let this part flex to fit inside grid item
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.closetItem.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ).copyWith(color: context.onCanvasText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.closetItem.category,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.33,
                      ).copyWith(color: context.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          context.read<ClosetItemBloc>().add(
            const LoadClosetItemsCacheFirstThenNetwork(''),
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
