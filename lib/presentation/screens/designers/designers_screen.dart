import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
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

    query = collectionRef.withConverter<Designer>(
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
      extendBody: true,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CustomFilterButton(
                    items: filters,
                    initialValue: 'All',
                    onSelect: (filter) {
                      setState(() {
                        selectedFilter = filter;
                        query = queryBuilder(filter);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshDesigners,
              child: BlocProvider(
                create: (_) => DesignerBloc()..add(LoadDesigners()),
                child: BlocBuilder<DesignerBloc, DesignerState>(
                  builder: (context, state) {
                    switch (state) {
                      case DesignerLoading():
                        return const Center(child: CircularProgressIndicator());
                      case DesignersLoaded(:final designers):
                        final filteredDesigners = _searchText.isEmpty
                            ? designers
                            : designers.where((designerSnap) {
                                final designer = designerSnap;
                                final name = designer.name
                                    .toLowerCase(); // adjust field
                                return name.contains(_searchText.toLowerCase());
                              }).toList();
                        // context.read<DesignerBloc>().add(
                        //   UpdateDesigners(filteredDesigners),
                        // );
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
                            final designer = filteredDesigners[index];
                            return DesignerInfoCardWidget(
                              designerInfo: designer,
                            );
                          },
                        );
                      case DesignerError(:final message):
                        debugPrint(message);
                        return Center(child: Text("Error: $message"));
                      default:
                        //return const Center(child: Text("No designers found"));
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
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Query<Designer> queryBuilder(String filter) {
    final query = collectionRef.withConverter<Designer>(
      fromFirestore: (snapshot, _) => Designer.fromJson(snapshot.data()!),
      toFirestore: (designer, _) => designer.toJson(),
    );

    switch (filter) {
      //['All', 'Trending', 'Newest', 'Top Rated', 'Favourites']
      case 'Newest':
        query.orderBy('created_date', descending: true);
        break;
      case 'Trending':
        query
            .where('ratings', isGreaterThan: 1)
            .orderBy('created_date', descending: true);
        break;
      case 'Top Rated':
        query
            .where('ratings', isGreaterThan: 1)
            .orderBy('created_date', descending: true);
        break;
      case 'Favourites':
        query
            .where('favourites', arrayContains: _authProviderCubit.state.uid)
            .orderBy('created_date', descending: true);
        break;
      default:
        query.orderBy('created_date', descending: true);
    }
    return query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
