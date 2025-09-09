import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_state.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_state.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_info_card_widget.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OutfitsPage extends StatefulWidget {
  const OutfitsPage({super.key});

  @override
  State<OutfitsPage> createState() => _OutfitsPageState();
}

class _OutfitsPageState extends State<OutfitsPage> {
  @override
  void initState() {
    context.read<ClosetOutfitBloc>().add(
      const LoadOutfitsCacheFirstThenNetwork(''),
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
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap:
                                true, // ✅ important for nesting in SliverToBoxAdapter
                            physics:
                                const NeverScrollableScrollPhysics(), // ✅ prevent scroll conflict
                            itemCount: outfits.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      (MediaQuery.of(context).size.width ~/ 180)
                                          .clamp(3, 6),
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.65,
                                ),
                            itemBuilder: (context, index) {
                              final outfit = outfits[index];
                              return OutfitInfoCardWidget(
                                outfitModel: outfit,
                                onPress: () {
                                  //_showBottomSheet(context, outfit);
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomIconButtonRounded(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          iconData: Icons.close,
                        ),
                        const SizedBox(width: 12),
                        CustomIconButtonRounded(
                          onPressed: () {},
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
                                      return ClosetItemInfoCardWidget(
                                        closetItem: closetItem,
                                        onPress: () {
                                          // make a selection
                                          // _showBottomSheet(context, closetItem);
                                        },
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
}
