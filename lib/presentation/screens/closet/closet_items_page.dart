import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_state.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_plan_screen.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_categories_widget.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:sliver_tools/sliver_tools.dart';

final RouteObserver<ModalRoute<void>> closetItemPageRouteObserver =
    RouteObserver<ModalRoute<void>>();

class ClosetItemsPage extends StatefulWidget {
  const ClosetItemsPage({super.key});

  @override
  State<ClosetItemsPage> createState() => _ClosetItemsPageState();
}

class _ClosetItemsPageState extends State<ClosetItemsPage> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  bool filterByFavourite = false;
  @override
  void initState() {
    context.read<ClosetItemBloc>().add(
      const LoadClosetItemsCacheFirstThenNetwork(''),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverAppBar(
          backgroundColor: colorScheme.surface,
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
                        decoration: InputDecoration(
                          hintText: "Search items...",
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
                      color: context.cardSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: context.hairline),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {},
                        child: const Icon(
                          Icons.filter_list_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// Categories header + chips
        SliverToBoxAdapter(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Categories",
                    style: textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.onCanvasText,
                    ),
                  ),
                ),
              ),
              ClosetItemCategoriesWidget(),
            ],
          ),
        ),

        BlocBuilder<ClosetItemBloc, ClosetItemBlocState>(
          builder: (context, state) {
            switch (state) {
              case ClosetItemLoading():
                return const SliverToBoxAdapter(
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );

              case ClosetItemsLoaded(:final closetItems):
                List<ClosetItemModel> filteredItems = _searchText.isEmpty
                    ? closetItems
                    : closetItems.where((item) {
                        final brand = item.brand!.toLowerCase();
                        final description = item.description.toLowerCase();
                        return brand.contains(_searchText.toLowerCase()) ||
                            description.contains(_searchText.toLowerCase());
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
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          (MediaQuery.of(context).size.width ~/ 180)
                              .clamp(3, 6),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final closetItem = filteredItems[index];
                      return ClosetItemInfoCardWidget(
                        closetItem: closetItem,
                        onPress: () {
                          _showBottomSheet(context, closetItem);
                        },
                      );
                    }, childCount: filteredItems.length),
                  ),
                );

              case ClosetItemError(:final message):
                return SliverToBoxAdapter(
                  child: Center(child: Text("Error: $message")),
                );

              default:
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
          },
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    closetItemPageRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    closetItemPageRouteObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  /// Called when coming back to this screen
  @override
  void didPopNext() {
    //debugPrint("ClientsScreen: didPopNext → refreshing clients");
    context.read<ClosetItemBloc>().add(
      const LoadClosetItemsCacheFirstThenNetwork(''),
    );
  }

  Future<void> _deleteClosetItem(ClosetItemModel closetItem) async {
    try {
      // create a dynamic list of futures
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final List<Future<dartz.Either>> futures = closetItem.featuredMedia
          .map((e) => sl<FirebaseClosetService>().deleteClosetItemImage(e.url!))
          .toList();

      // also add delete by id
      futures.add(sl<FirebaseClosetService>().deleteClosetItem(closetItem));

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
      // context.read<ClosetItemBloc>().add(
      //   LoadClosetItemsCacheFirstThenNetwork(''),
      // );

      context.read<ClosetItemBloc>().add(DeleteClosetItem(closetItem));

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  void _showBottomSheet(BuildContext context, ClosetItemModel closetItem) {
    final thumbnailUrl = closetItem.featuredMedia.isNotEmpty
        ? closetItem.featuredMedia.first.url
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.canvasBackground,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85, // how tall it opens initially
          minChildSize: 0.55,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Hero image (full-bleed, bleeds behind the rounded corners)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: thumbnailUrl ?? '',
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
                        /// Bottom scrim fading the photo into the panel
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.28),
                              ],
                              stops: const [0.55, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Content panel
                  Container(
                    color: context.canvasBackground,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Title + brand chip
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                closetItem.description,
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: context.onCanvasText,
                                ),
                              ),
                            ),
                            if (closetItem.brand != null) ...[
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.hairline),
                                ),
                                child: Text(
                                  closetItem.brand!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.secondaryLabel,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        /// Category
                        Text(
                          "Category: ${closetItem.category}",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.secondaryLabel,
                          ),
                        ),

                        if ((closetItem.colors ?? []).isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final color in closetItem.colors!)
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(color),
                                    border: Border.all(
                                      color: context.hairline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        /// Add to planner + favourite
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddOrEditOutfitPlanScreen(
                                          outfitPlan: OutfitPlanModel.empty()
                                              .copyWith(
                                                occassion:
                                                    closetItem.description,
                                                thumbnailUrl: thumbnailUrl,
                                                outfitItem: OutfitClosetItem
                                                    .empty()
                                                    .copyWith(
                                                      thumbnailUrl:
                                                          thumbnailUrl,
                                                      uid: closetItem.uid!,
                                                      featuredMedia: closetItem
                                                          .featuredMedia,
                                                      description: closetItem
                                                          .description,
                                                      category: closetItem
                                                          .category,
                                                    ),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: context.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                  ),
                                  label: const Text("Add to Planner"),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Material(
                                color: context.cardSurface,
                                shape: CircleBorder(
                                  side: BorderSide(color: context.hairline),
                                ),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    addOrRemoveFromFavourite(closetItem);
                                  },
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        closetItem.isFavourite!
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        key: ValueKey(
                                          closetItem.isFavourite!,
                                        ),
                                        color: closetItem.isFavourite!
                                            ? context.accent
                                            : context.secondaryLabel,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// Divider
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: context.hairline,
                        ),

                        const SizedBox(height: 12),

                        /// Edit / Delete
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddOrEditClosetItemsPage(
                                        closetItemModel: closetItem,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: context.onCanvasText,
                                ),
                                label: Text(
                                  "Edit",
                                  style: TextStyle(
                                    color: context.onCanvasText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.hairline),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
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
                                    _deleteClosetItem(closetItem);
                                  }
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                label: Text(
                                  "Delete",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> addOrRemoveFromFavourite(ClosetItemModel closetItem) async {
    try {
      final result = await sl<FirebaseClosetService>()
          .addOrRemoveFavouriteClosetItem(closetItem.uid!);
      result.fold(
        (l) => debugPrint("Error adding or removing favourite closet item: $l"),
        (r) {
          setState(() {
            closetItem = closetItem.copyWith(isFavourite: r);
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
