import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_state.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_state.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_screen.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_info_card_widget.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class OutfitsPage extends StatefulWidget {
  const OutfitsPage({super.key});

  @override
  State<OutfitsPage> createState() => _OutfitsPageState();
}

class _OutfitsPageState extends State<OutfitsPage> {
  late List<ClosetItemModel> selectedClosetItems = [];

  @override
  void initState() {
    context.read<ClosetOutfitBloc>().add(
      const LoadOutfitsCacheFirstThenNetwork(''),
    );
    super.initState();
  }

  @override
  void dispose() {
    selectedClosetItems.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            pinned: true, // keeps the searchbar visible when collapsed
            floating: true, // allows it to appear/disappear as you scroll
            snap: true, // snaps into view when scrolling up
            stretch: true,
            expandedHeight: 10,
            toolbarHeight: 5,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search outfits...",
                          hintStyle: textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          // TODO: trigger search/filter logic
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomIconButtonRounded(
                      onPressed: () {},
                      iconData: Icons.favorite_outline,
                    ),
                    const SizedBox(width: 8),
                    CustomIconButtonRounded(
                      onPressed: () {},
                      iconData: Icons.filter_list_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),

          BlocBuilder<ClosetOutfitBloc, ClosetOutfitBlocState>(
            builder: (context, state) {
              switch (state) {
                case OutfitLoading():
                  return const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  );

                case OutfitsLoaded(:final outfits):
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MasonryGridView.count(
                            padding: EdgeInsets.zero,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            shrinkWrap:
                                true, // ✅ important for nesting in SliverToBoxAdapter
                            physics:
                                const NeverScrollableScrollPhysics(), // ✅ prevent scroll conflict
                            itemCount: outfits.length,
                            crossAxisCount:
                                (MediaQuery.of(context).size.width ~/ 160)
                                    .clamp(2, 4),
                            itemBuilder: (context, index) {
                              final outfit = outfits[index];
                              return OutfitInfoCardWidget(
                                outfitModel: outfit,
                                onPress: () {
                                  _showDetailsBottomSheet(context, outfit);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );

                case OutfitError(:final message):
                  return SliverToBoxAdapter(
                    child: Center(child: Text("Error: $message")),
                  );

                default:
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: PageEmptyWidget(
                          title: "Your closet is empty",
                          subtitle: "Add some items to your closet",
                          icon: Icons.checkroom,
                          iconSize: 48,
                        ),
                      ),
                    ),
                  );
              }
            },
          ),
        ],
      ),
      floatingActionButton: Hero(
        tag: 'add-item-button',
        child: Material(
          color: colorScheme.primary,
          elevation: 6,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              showAddOutfitBottomSheet(context, OutfitModel.empty());
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsBottomSheet(BuildContext context, OutfitModel outfit) {
    final random = Random();
    final List<FeaturedMediaModel> featuredMedia = outfit.closetItems.map((
      item,
    ) {
      return item.featuredMedia.first;
    }).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7, // how tall it opens initially
          minChildSize: 0.7,
          maxChildSize: 0.9,
          shouldCloseOnMinExtent: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Handle bar
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    //const SizedBox(height: 8),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MasonryGridView.builder(
                        padding: const EdgeInsets.all(0),
                        shrinkWrap:
                            true, // ✅ important when inside SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // ✅ let parent handle scroll
                        cacheExtent: 10,
                        gridDelegate:
                            SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: featuredMedia.length > 4 ? 3 : 2,
                            ),
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        itemCount: featuredMedia.length,
                        itemBuilder: (context, index) {
                          final preview = featuredMedia[index];
                          // 👇 Assign different aspect ratios randomly for variety
                          final aspectRatioOptions = [1 / 1];
                          final aspectRatio =
                              aspectRatioOptions[random.nextInt(
                                aspectRatioOptions.length,
                              )];
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: CachedNetworkImage(
                                imageUrl: preview.url!.isEmpty
                                    ? ''
                                    : preview.url!.trim(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return const CustomColoredBanner(text: '');
                                },
                                errorListener: (value) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                outfit.style ?? '',
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            CustomIconButtonRounded(
                              iconData: Icons.favorite_outline,
                              size: 24,
                              onPressed: () => addOrRemoveFromFavourite(outfit),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  outfit.isFavourite!
                                      ? Icons.favorite
                                      : Icons.favorite_outline,
                                  key: ValueKey(outfit.isFavourite!),
                                  color: outfit.isFavourite!
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          outfit.occassion,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: -6, // 👈 reduced padding
                      children: outfit.tags!.isEmpty
                          ? [SizedBox(height: 1)]
                          : outfit.tags!
                                .split('|')
                                .where(
                                  (tag) => tag.trim().isNotEmpty,
                                ) // ✅ only keep non-empty tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: handle add to planner
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: const Text("Add to planner"),
                            style: OutlinedButton.styleFrom(
                              elevation: 0, // ✅ no elevation
                              side: const BorderSide(
                                color: Colors.grey,
                              ), // ✅ grey border
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ), // optional: rounded edges
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomIconButtonRounded(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddOrEditOutfitScreen(outfitModel: outfit),
                              ),
                            );
                          },
                          size: 24,
                          iconData: Icons.edit,
                        ),
                        const SizedBox(width: 12),
                        CustomIconButtonRounded(
                          onPressed: () async {
                            final canDelete = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Item'),
                                content: const Text(
                                  'Are you sure you want to delete this item?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (canDelete == true) {
                              //_deleteClosetItem(closetItem);
                            }
                          },
                          iconData: Icons.delete,
                          icon: Icon(Icons.delete, color: Colors.red, size: 24),
                          //backgroundColor: Colors.red.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showAddOutfitBottomSheet(BuildContext context, OutfitModel outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9, // how tall it opens initially
          minChildSize: 0.7,
          maxChildSize: 0.9,
          shouldCloseOnMinExtent: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomIconButtonRounded(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          iconData: Icons.arrow_back,
                        ),
                        const SizedBox(width: 12),
                        CustomIconButtonRounded(
                          onPressed: () {
                            if (selectedClosetItems.isEmpty) return;
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddOrEditOutfitScreen(
                                  outfitModel: OutfitModel.empty().copyWith(
                                    closetItems: selectedClosetItems
                                        .map(
                                          (item) =>
                                              OutfitClosetItem.fromClosetItem(
                                                item,
                                              ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            );
                            //selectedClosetItems.clear();
                          },
                          iconData: Icons.check,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Select multiple items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),

                    const SizedBox(height: 16),
                    BlocBuilder<ClosetItemBloc, ClosetItemBlocState>(
                      builder: (context, state) {
                        switch (state) {
                          case ClosetItemLoading():
                            return Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(),
                              ),
                            );

                          case ClosetItemsLoaded(:final closetItems):
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Items",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  GridView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap:
                                        true, // ✅ important for nesting in SliverToBoxAdapter
                                    physics:
                                        const NeverScrollableScrollPhysics(), // ✅ prevent scroll conflict
                                    itemCount: closetItems.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              (MediaQuery.of(
                                                        context,
                                                      ).size.width ~/
                                                      180)
                                                  .clamp(3, 6),
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                          childAspectRatio: 0.65,
                                        ),
                                    itemBuilder: (context, index) {
                                      final closetItem = closetItems[index];
                                      final isSelected = selectedClosetItems
                                          .contains(closetItem);
                                      return ClosetItemInfoCardWidget(
                                        closetItem: closetItem.copyWith(
                                          isSelected: isSelected,
                                        ),
                                        onSelect: () =>
                                            toggleSelection(closetItem),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );

                          case ClosetItemError(:final message):
                            return Center(child: Text("Error: $message"));

                          default:
                            return SizedBox(
                              height: 400,
                              child: Center(
                                child: PageEmptyWidget(
                                  title: "Your closet is empty",
                                  subtitle: "Add some items to your closet",
                                  icon: Icons.checkroom,
                                  iconSize: 48,
                                ),
                              ),
                            );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void toggleSelection(ClosetItemModel item) {
    //debugPrint('selected: ${selectedClosetItems.contains(item)}');
    setState(() {
      if (selectedClosetItems.contains(item)) {
        selectedClosetItems.remove(item);
      } else {
        selectedClosetItems.add(item);
      }
    });
  }

  Future<void> addOrRemoveFromFavourite(OutfitModel outfit) async {
    try {
      final result = await sl<FirebaseClosetService>()
          .addOrRemoveFavouriteOutfit(outfit.uid!);
      result.fold(
        (l) => debugPrint("Error adding or removing favourite outfit: $l"),
        (r) {
          setState(() {
            outfit = outfit.copyWith(isFavourite: r);
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
