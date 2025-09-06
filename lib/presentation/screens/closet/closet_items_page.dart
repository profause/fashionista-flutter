import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_state.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_categories_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
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
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final closetItem = closetItems[index];
                      return ListTile(title: Text("Closet item $index"));
                    }, childCount: closetItems.length),
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
                          icon: Icons.people_outline,
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
}
