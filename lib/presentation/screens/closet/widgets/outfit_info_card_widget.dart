
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(16),
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
            _buildCompositeImage(context, featuredMedia),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.outfitModel.style ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ).copyWith(color: context.onCanvasText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => addOrRemoveFromFavourite(
                          widget.outfitModel.uid!,
                        ),
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
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.outfitModel.occassion,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ).copyWith(color: context.mutedText),
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

  Widget _buildCompositeImage(
    BuildContext context,
    List<FeaturedMediaModel> media,
  ) {
    final items = media.take(4).toList();
    final hairline = context.hairline;

    Widget borderedCell(
      int index, {
      bool rightDivider = false,
      bool bottomDivider = false,
    }) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            right: rightDivider
                ? BorderSide(color: hairline)
                : BorderSide.none,
            bottom: bottomDivider
                ? BorderSide(color: hairline)
                : BorderSide.none,
          ),
        ),
        child: _imageCell(items[index]),
      );
    }

    Widget content;
    if (items.isEmpty) {
      content = const SizedBox.shrink();
    } else if (items.length == 1) {
      content = borderedCell(0);
    } else if (items.length == 2) {
      content = Row(
        children: [
          Expanded(child: borderedCell(0, rightDivider: true)),
          Expanded(child: borderedCell(1)),
        ],
      );
    } else if (items.length == 3) {
      content = Row(
        children: [
          Expanded(child: borderedCell(0, rightDivider: true)),
          Expanded(
            child: Column(
              children: [
                Expanded(child: borderedCell(1, bottomDivider: true)),
                Expanded(child: borderedCell(2)),
              ],
            ),
          ),
        ],
      );
    } else {
      content = Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: borderedCell(
                    0,
                    rightDivider: true,
                    bottomDivider: true,
                  ),
                ),
                Expanded(child: borderedCell(1, bottomDivider: true)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: borderedCell(2, rightDivider: true)),
                Expanded(child: borderedCell(3)),
              ],
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: context.iconSubstrate,
          border: Border(bottom: BorderSide(color: hairline)),
        ),
        child: content,
      ),
    );
  }

  Widget _imageCell(FeaturedMediaModel preview) {
    return SizedBox.expand(
      child: CachedNetworkImage(
        imageUrl: preview.url!.isEmpty ? '' : preview.url!.trim(),
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
