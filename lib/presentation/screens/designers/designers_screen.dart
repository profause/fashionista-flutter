import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/screens/designers/widgets/designer_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/custom_filter_button.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignersScreen extends StatefulWidget {
  const DesignersScreen({super.key});

  @override
  State<DesignersScreen> createState() => _DesignersScreenState();
}

class _DesignersScreenState extends State<DesignersScreen> {
  late CollectionReference<Designer> collection;
  late Query<Designer> query;
  late AuthProviderCubit _authProviderCubit;
  //bool _isLoading = false;
  final collectionRef = FirebaseFirestore.instance.collection('designers');
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String selectedFilter = 'All';

  @override
  void initState() {
    //_isLoading = false;
    //if (mounted) {
    _authProviderCubit = context.read<AuthProviderCubit>();

    collection = collectionRef.withConverter<Designer>(
      fromFirestore: (snapshot, _) => Designer.fromJson(snapshot.data()!),
      toFirestore: (designer, _) => designer.toJson(),
    );

    query = collectionRef
        .withConverter<Designer>(
          fromFirestore: (snapshot, _) => Designer.fromJson(snapshot.data()!),
          toFirestore: (designer, _) => designer.toJson(),
        );

    //}
    setState(() {
      selectedFilter = 'All';
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filters = ['All', 'Trending', 'Newest', 'Top Rated', 'Favourites'];
    Future<void> refreshDesigners() async {
      // Force rebuild StreamBuilder by calling setState
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 500)); // optional
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            // Incoming: slide in from right
            final inAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0), // from right
              end: Offset.zero,
            ).animate(animation);

            // Outgoing: shrink/slide away from center
            final outAnimation = Tween<Offset>(
              begin: Offset.zero, // start at center
              end: const Offset(0.0, 0.0), // move slightly up
            ).animate(animation);

            if (child.key == const ValueKey("searchField")) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: inAnimation, child: child),
              );
            } else {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: outAnimation, child: child),
              );
            }
          },
          child: _isSearching
              ? TextField(
                  key: const ValueKey("searchField"),
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search designers...',
                    border: InputBorder.none,
                    hintStyle: textTheme.titleSmall,
                  ),
                  style: textTheme.bodyMedium,
                  onChanged: (value) {
                    setState(() => _searchText = value);
                  },
                )
              : const AppBarTitle(title: "Designers"),
        ),

        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                size: 30,
                color: colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchText = "";
                    _searchController.clear();
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected =
                      filter == selectedFilter ||
                      (selectedFilter == '' && filter == 'All');
                  return CustomFilterButton(
                    title: filter,
                    isSelectedNotifier: ValueNotifier(isSelected),
                    onSelect: (title) {
                      setState(() {
                        selectedFilter = title;
                        query = queryBuilder('All');
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshDesigners,
              child: StreamBuilder<QuerySnapshot<Designer>>(
                stream: query
                    //.where('created_by', isEqualTo: _authProviderCubit.state.uid)
                    .orderBy('ratings', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint("Error: ${snapshot.error}");
                    return SizedBox(
                      height: 400,
                      child: Center(
                        child: PageEmptyWidget(
                          title: "No Designers Found",
                          subtitle: "Error: ${snapshot.error}",
                          icon: Icons.newspaper_outlined,
                        ),
                      ),
                    );
                    //return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  final designers = snapshot.data?.docs ?? [];
                  if (designers.isEmpty) {
                    return ListView(
                      // Needed so pull-to-refresh still works
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 400,
                          child: Center(
                            child: PageEmptyWidget(
                              title: "No Designers Found",
                              subtitle: "Refresh to try again",
                              icon: Icons.people_outline,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // inside your build method
                  final filteredDesigners = _searchText.isEmpty
                      ? designers
                      : designers.where((designerSnap) {
                          final designer = designerSnap.data();
                          final name = designer.name
                              .toLowerCase(); // adjust field
                          return name.contains(_searchText.toLowerCase());
                        }).toList();
                  if (filteredDesigners.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 400,
                          child: Center(
                            child: PageEmptyWidget(
                              title: "No Designers Found",
                              subtitle: "Refresh to try again",
                              icon: Icons.people_outline,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredDesigners.length,
                    itemBuilder: (context, index) {
                      final designer = filteredDesigners[index].data();
                      return DesignerInfoCardWidget(designerInfo: designer);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Query<Designer> queryBuilder(filter) {
    final query = collectionRef
        .withConverter<Designer>(
          fromFirestore: (snapshot, _) => Designer.fromJson(snapshot.data()!),
          toFirestore: (designer, _) => designer.toJson(),
        );

    return query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
