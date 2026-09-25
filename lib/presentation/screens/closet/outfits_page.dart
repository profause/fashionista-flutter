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
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_plan_screen.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_screen.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_info_card_widget.dart';
import 'package:fashionista/presentation/screens/closet/widgets/selectable_closet_item_card.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:sliver_tools/sliver_tools.dart';

class OutfitsPage extends StatefulWidget {
  const OutfitsPage({super.key});

  @override
  State<OutfitsPage> createState() => OutfitsPageState();
}

class OutfitsPageState extends State<OutfitsPage> {
  late List<ClosetItemModel> selectedClosetItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  bool filterByFavourite = false;

  @override
  void initState() {
    context.read<ClosetOutfitBloc>().add(
      const LoadOutfitsCacheFirstThenNetwork(''),
    );

    setState(() {
      filterByFavourite = false;
    });
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

    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverAppBar(
          backgroundColor: context.canvasBackground,
          pinned: true, // keeps the searchbar visible when collapsed
          floating: true, // allows it to appear/disappear as you scroll
          snap: true, // snaps into view when scrolling up
          stretch: true,
          expandedHeight: 18,
          toolbarHeight: 5,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search outfits...",
                          hintStyle: textTheme.bodyMedium!.copyWith(
                            color: context.mutedText,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          prefixIconColor: context.secondaryLabel,
                          filled: true,
                          fillColor: context.cardSurface,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.hairline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.hairline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.accent.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchText = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      color: context.cardSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: context.hairline),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() {
                          filterByFavourite = !filterByFavourite;
                        }),
                        child: Icon(
                          filterByFavourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: filterByFavourite
                              ? context.accent
                              : context.onCanvasText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      color: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: context.hairline),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => {
                          showAddOutfitBottomSheet(
                            context,
                            OutfitModel.empty(),
                          ),
                        },
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
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
                List<OutfitModel> filteredItems = _searchText.isEmpty
                    ? outfits
                    : outfits.where((item) {
                        final occassion = item.occassion.toLowerCase();
                        final style = item.style!.toLowerCase();
                        final tags = item.tags!.toLowerCase();
                        return occassion.contains(_searchText.toLowerCase()) ||
                            tags.contains(_searchText.toLowerCase()) ||
                            style.contains(_searchText.toLowerCase());
                      }).toList();

                filteredItems = !filterByFavourite
                    ? filteredItems
                    : filteredItems
                          .where((item) => item.isFavourite == true)
                          .toList();

                if (filteredItems.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
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
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MasonryGridView.count(
                          padding: EdgeInsets.zero,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          shrinkWrap:
                              true, // ✅ important for nesting in SliverToBoxAdapter
                          physics:
                              const NeverScrollableScrollPhysics(), // ✅ prevent scroll conflict
                          itemCount: filteredItems.length,
                          crossAxisCount:
                              (MediaQuery.of(context).size.width ~/ 160).clamp(
                                2,
                                4,
                              ),
                          itemBuilder: (context, index) {
                            final outfit = filteredItems[index];
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
    );
    // return Scaffold(
    //   backgroundColor: colorScheme.surface,
    //   body: CustomScrollView(
    //     slivers: [

    //     ],
    //   ),
    //   floatingActionButton: Hero(
    //     tag: 'add-item-button',
    //     child: Material(
    //       color: colorScheme.primary,
    //       elevation: 6,
    //       shape: const CircleBorder(),
    //       child: InkWell(
    //         onTap: () {
    //           showAddOutfitBottomSheet(context, OutfitModel.empty());
    //         },
    //         customBorder: const CircleBorder(),
    //         child: SizedBox(
    //           width: 56,
    //           height: 56,
    //           child: Icon(Icons.add, color: colorScheme.onPrimary),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  void _showDetailsBottomSheet(BuildContext context, OutfitModel outfit) {
    final thumbnailUrl = outfit.thumbnailUrl ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          shouldCloseOnMinExtent: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 6,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: context.softBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        _buildLookbookMedia(context, outfit),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => addOrRemoveFromFavourite(outfit),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    outfit.isFavourite!
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    key: ValueKey(outfit.isFavourite!),
                                    color: outfit.isFavourite!
                                        ? context.accent
                                        : Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      outfit.style ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                        color: context.onCanvasText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${outfit.occassion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: outfit.tags!.isEmpty
                          ? [const SizedBox(height: 1)]
                          : outfit.tags!
                                .split('|')
                                .where((tag) => tag.trim().isNotEmpty)
                                .map(
                                  (tag) => Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.iconSubstrate,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: context.hairline,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tag.trim(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: context.descriptionText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: Material(
                              color: context.accent,
                              elevation: 0,
                              shadowColor: context.accent.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddOrEditOutfitPlanScreen(
                                        outfitPlan: OutfitPlanModel.empty()
                                            .copyWith(
                                              occassion: outfit.occassion,
                                              date: 0,
                                              thumbnailUrl: thumbnailUrl,
                                              recurrenceEndDate: 0,
                                              outfitItem:
                                                  OutfitClosetItem.empty()
                                                      .copyWith(
                                                        thumbnailUrl:
                                                            thumbnailUrl,
                                                        uid: outfit.uid,
                                                        featuredMedia: outfit
                                                            .closetItems
                                                            .map((item) {
                                                              return item
                                                                  .featuredMedia
                                                                  .first;
                                                            })
                                                            .toList(),
                                                        description:
                                                            outfit.occassion,
                                                        category: outfit
                                                            .closetItems
                                                            .first
                                                            .category,
                                                      ),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add to Planner',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Material(
                            color: context.secondaryButtonBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.hairline),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddOrEditOutfitScreen(
                                      outfitModel: outfit,
                                    ),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.edit,
                                size: 20,
                                color: context.onCanvasText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Material(
                            color: colorScheme.errorContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.error.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () async {
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
                                          foregroundColor: Theme.of(
                                            ctx,
                                          ).colorScheme.error,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (canDelete == true) {
                                  _deleteOutfit(outfit);
                                }
                              },
                              child: Icon(
                                Icons.delete,
                                size: 20,
                                color: colorScheme.error,
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
          },
        );
      },
    );
  }

  Widget _buildLookbookMedia(BuildContext context, OutfitModel outfit) {
    final thumbnailUrl = outfit.thumbnailUrl ?? '';
    final items = outfit.closetItems.take(4).toList();
    final hairline = context.hairline;

    Widget cellOf(
      OutfitClosetItem item, {
      bool rightD = false,
      bool bottomD = false,
    }) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            right: rightD ? BorderSide(color: hairline) : BorderSide.none,
            bottom: bottomD ? BorderSide(color: hairline) : BorderSide.none,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _lookbookCellImage(item),
            if (item.category.trim().isNotEmpty)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    item.category.trim().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget content;
    if (thumbnailUrl.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: thumbnailUrl,
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
        errorListener: (value) {},
      );
    } else if (items.isEmpty) {
      content = const CustomColoredBanner(text: '');
    } else if (items.length == 1) {
      content = cellOf(items[0]);
    } else if (items.length == 2) {
      content = Row(
        children: [
          Expanded(child: cellOf(items[0], rightD: true)),
          Expanded(child: cellOf(items[1])),
        ],
      );
    } else if (items.length == 3) {
      content = Row(
        children: [
          Expanded(child: cellOf(items[0], rightD: true)),
          Expanded(
            child: Column(
              children: [
                Expanded(child: cellOf(items[1], bottomD: true)),
                Expanded(child: cellOf(items[2])),
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
                Expanded(child: cellOf(items[0], rightD: true, bottomD: true)),
                Expanded(child: cellOf(items[1], bottomD: true)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: cellOf(items[2], rightD: true)),
                Expanded(child: cellOf(items[3])),
              ],
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.iconSubstrate,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hairline),
        ),
        child: content,
      ),
    );
  }

  Widget _lookbookCellImage(OutfitClosetItem item) {
    if (item.featuredMedia.isEmpty) {
      return const CustomColoredBanner(text: '');
    }
    final url = item.featuredMedia.first.url ?? '';
    return CachedNetworkImage(
      imageUrl: url.isEmpty ? '' : url.trim(),
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => const CustomColoredBanner(text: ''),
      errorListener: (value) {},
    );
  }

  void showAddOutfitBottomSheet(BuildContext context, OutfitModel outfit) {
    selectedClosetItems.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        side: BorderSide(color: context.hairline),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void toggleItem(ClosetItemModel item) {
              toggleSelection(item);
              setSheetState(() {});
            }

            void confirmSelection() {
              if (selectedClosetItems.isEmpty) return;
              Navigator.pop(sheetContext);
              Navigator.push(
                sheetContext,
                MaterialPageRoute(
                  builder: (_) => AddOrEditOutfitScreen(
                    outfitModel: OutfitModel.empty().copyWith(
                      closetItems: selectedClosetItems
                          .map((item) => OutfitClosetItem.fromClosetItem(item))
                          .toList(),
                    ),
                  ),
                ),
              );
            }

            final selectedCount = selectedClosetItems.length;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9, // how tall it opens initially
              minChildSize: 0.55,
              maxChildSize: 0.95,
              shouldCloseOnMinExtent: false,
              builder: (sheetContext, scrollController) {
                return Column(
                  children: [
                    // Grabber handle
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.softBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    // Sheet navigation header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.iconSubstrate,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: context.onCanvasText,
                                weight: 600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Select Multiple Items',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: context.onCanvasText,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: confirmSelection,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.accent,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.accent.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Done ($selectedCount)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Main content (sub-header + scrollable grid)
                    Expanded(
                      child: BlocBuilder<ClosetItemBloc, ClosetItemBlocState>(
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
                              final width = MediaQuery.sizeOf(context).width;
                              final crossAxisCount = ((width - 32) / 170)
                                  .floor()
                                  .clamp(3, 6);
                              final cellWidth =
                                  (width - 32 - 12 * (crossAxisCount - 1)) /
                                  crossAxisCount;
                              final cellHeight =
                                  cellWidth * 5 / 4 +
                                  52; // 4:5 image + caption ~52px
                              final childAspectRatio = cellWidth / cellHeight;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sub-header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'ITEMS',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                            color: context.onCanvasText,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.hairline.withValues(
                                              alpha: 0.7,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: context.hairline,
                                            ),
                                          ),
                                          child: Text(
                                            '${closetItems.length} total',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: context.descriptionText,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: context.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text.rich(
                                          TextSpan(
                                            text: 'Selected: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: context.secondaryLabel,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '$selectedCount items',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.accent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: context.iconSubstrate,
                                  ),
                                  const SizedBox(height: 14),
                                  // Wardrobe grid
                                  Expanded(
                                    child: GridView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        24,
                                      ),
                                      itemCount: closetItems.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: childAspectRatio,
                                          ),
                                      itemBuilder: (context, index) {
                                        final closetItem = closetItems[index];
                                        final isSelected = selectedClosetItems
                                            .contains(closetItem);
                                        return SelectableClosetItemCard(
                                          closetItem: closetItem,
                                          isSelected: isSelected,
                                          onTap: () => toggleItem(closetItem),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );

                            case ClosetItemError(:final message):
                              return Center(child: Text("Error: $message"));

                            default:
                              return Center(
                                child: PageEmptyWidget(
                                  title: "Your closet is empty",
                                  subtitle: "Add some items to your closet",
                                  icon: Icons.checkroom,
                                  iconSize: 48,
                                ),
                              );
                          }
                        },
                      ),
                    ),
                    // Sticky bottom dock
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        border: Border(
                          top: BorderSide(color: context.hairline),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.accent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$selectedCount items selected • Ready to assemble outfit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: context.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: confirmSelection,
                            child: Container(
                              height: 48,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: context.accent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.accent.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Confirm Selection ($selectedCount)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: 134,
                              height: 5,
                              decoration: BoxDecoration(
                                color: context.onCanvasText.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _deleteOutfit(OutfitModel outfit) async {
    try {
      // create a dynamic list of futures
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final List<Future<dartz.Either>> futures = [];
      // sl<FirebaseClosetService>().deleteClosetItemImage(
      //   outfit.thumbnailUrl!,
      // );

      // also add delete by id
      futures.add(sl<FirebaseClosetService>().deleteOutfit(outfit));

      futures.add(
        sl<FirebaseClosetService>().deleteOutfitPlanWhenOutfitIsDeleted(outfit),
      );

      // wait for all and capture results
      final results = await Future.wait(futures);

      // handle each result
      for (final result in results) {
        result.fold(
          (failure) {
            // handle failure
            debugPrint("Delete failed: $failure");
          },
          (success) {
            // handle success
            debugPrint("Delete success: $success");
          },
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      context.read<ClosetOutfitBloc>().add(
        const LoadOutfitsCacheFirstThenNetwork(''),
      );
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
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
