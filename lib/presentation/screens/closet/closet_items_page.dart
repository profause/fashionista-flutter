import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_state.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_categories_widget.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final RouteObserver<ModalRoute<void>> closetItemPageRouteObserver =
    RouteObserver<ModalRoute<void>>();

class ClosetItemsPage extends StatefulWidget {
  const ClosetItemsPage({super.key});

  @override
  State<ClosetItemsPage> createState() => _ClosetItemsPageState();
}

class _ClosetItemsPageState extends State<ClosetItemsPage> with RouteAware {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          /// Collapsible SearchBar
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
                          hintText: "Search items...",
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

          /// Example Horizontal Chips
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Categories", style: textTheme.titleLarge),
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
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Items",
                            style: Theme.of(context).textTheme.titleLarge,
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
                                      (MediaQuery.of(context).size.width ~/ 180)
                                          .clamp(3, 6),
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.7,
                                ),
                            itemBuilder: (context, index) {
                              final closetItem = closetItems[index];
                              return ClosetItemInfoCardWidget(
                                closetItem: closetItem,
                                onPress: () {
                                  _showBottomSheet(context, closetItem);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );

                case ClosetItemError(:final message):
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

          // SliverList(
          //   delegate: SliverChildBuilderDelegate(
          //     (context, index) => ListTile(title: Text("Closet item $index")),
          //     childCount: 30, // mock items
          //   ),
          // ),
        ],
      ),

      floatingActionButton: Hero(
        tag: 'add-item-button',
        child: Material(
          color: colorScheme.primary,
          elevation: 6,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddOrEditClosetItemsPage(),
                ),
              );

              if (result == true && mounted) {
                // context.read<ClosetItemBloc>().add(
                //   const LoadCloserItemsCacheFirstThenNetwork(''),
                // );
              }
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

  void _showBottomSheet(BuildContext context, ClosetItemModel closetItem) {
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
          minChildSize: 0.4,
          maxChildSize: 0.7,
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

                    /// Item Image
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: closetItem.featuredMedia.first.url!.trim(),
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
                    ),
                    const SizedBox(height: 8),

                    /// Title + Brand
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      closetItem.description ?? "Unnamed Item",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),

                                  if (closetItem.brand != null) ...[
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        closetItem.brand!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelLarge,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            CustomIconButtonRounded(
                              size: 24,
                              iconData: Icons.favorite_outline,
                              onPressed: () async {
                                addOrRemoveFromFavourite(closetItem);
                              },
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
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
                                      : Icons.favorite_outline,
                                  key: ValueKey(
                                    closetItem.isFavourite!,
                                  ), // important for switcher
                                  color: closetItem.isFavourite!
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Selected colors
                              for (final color in closetItem.colors!)
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(color),
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CustomIconButtonRounded(
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
                                size: 24,
                                iconData: Icons.edit,
                              ),
                              const SizedBox(width: 12),
                              CustomIconButtonRounded(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<ClosetItemBloc>().add(
                                    DeleteClosetItem(closetItem),
                                  );
                                },
                                iconData: Icons.delete,
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                //backgroundColor: Colors.red.shade400,
                              ),
                            ],
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
