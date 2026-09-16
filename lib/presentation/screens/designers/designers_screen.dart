import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/theme/app.theme.dart';
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
  static const List<String> filters = [
    'All',
    'Trending',
    'Newest',
    'Top Rated',
    'Favourites',
  ];

  late CollectionReference<Designer> collection;
  late Query<Designer> query;
  late AuthProviderCubit _authProviderCubit;
  final collectionRef = FirebaseFirestore.instance.collection('designers');
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String selectedFilter = 'All';

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> refreshDesigners() async {
    context.read<DesignerBloc>().add(LoadDesignersCacheFirstThenNetwork());
  }

  @override
  void initState() {
    _authProviderCubit = context.read<AuthProviderCubit>();

    collection = collectionRef.withConverter<Designer>(
      fromFirestore: (snapshot, _) => Designer.fromJson(snapshot.data()!),
      toFirestore: (designer, _) => designer.toJson(),
    );

    query = collectionRef.withConverter<Designer>(
      fromFirestore: (snapshot, _) => Designer.fromJson(snapshot.data()!),
      toFirestore: (designer, _) => designer.toJson(),
    );

    selectedFilter = 'All';
    super.initState();
  }

  void _selectFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      query = queryBuilder(filter);
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardSurface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Filter Options',
                  style: Theme.of(sheetContext).textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ...filters.map((filter) {
                final isSelected = selectedFilter == filter;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? context.accent : context.mutedText,
                  ),
                  title: Text(filter),
                  trailing:
                      const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    _selectFilter(filter);
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  List<Designer> _filterBySearch(List<Designer> designers) {
    if (_searchText.isEmpty) return designers;
    final q = _searchText.toLowerCase();
    return designers.where((d) {
      return d.name.toLowerCase().contains(q) ||
          d.businessName.toLowerCase().contains(q) ||
          d.location.toLowerCase().contains(q) ||
          d.tags.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBody: false,
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        foregroundColor: context.accent,
        backgroundColor: context.cardSurface,
        title: const AppBarTitle(title: "Designers"),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchText = value),
                      decoration: InputDecoration(
                        hintText: 'Search atelier, couturier, craft...',
                        hintStyle: textTheme.bodyMedium!
                            .copyWith(color: context.mutedText),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: context.mutedText,
                        ),
                        filled: true,
                        fillColor: context.cardSurface,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.accent,
                            width: 1.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.hairline),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, size: 22),
                    color: context.onCanvasText,
                    tooltip: 'Filter Options',
                    onPressed: _showFilterSheet,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CustomFilterButton(
                  items: filters,
                  initialValue: 'All',
                  onSelect: _selectFilter,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: BlocProvider(
              create: (_) =>
                  DesignerBloc()..add(LoadDesignersCacheFirstThenNetwork()),
              child: BlocListener<DesignerBloc, DesignerState>(
                listener: (context, state) {
                  if (state is DesignerLoading) {
                    // 👇 show RefreshIndicator programmatically
                    _refreshKey.currentState?.show();
                  }
                },
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: refreshDesigners,
                  child: BlocBuilder<DesignerBloc, DesignerState>(
                    builder: (context, state) {
                      switch (state) {
                        case DesignerLoading():
                          // ⛔ Don’t use CircularProgressIndicator
                          // Let RefreshIndicator handle it
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [SizedBox(height: 400)],
                          );
                        case DesignersLoaded(
                          :final designers,
                        ):
                          final filteredDesigners = _filterBySearch(designers);

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
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            itemCount: filteredDesigners.length,
                            itemBuilder: (context, index) {
                              final designer = filteredDesigners[index];
                              return DesignerInfoCardWidget(
                                designerInfo: designer,
                              );
                            },
                          );

                        case DesignerError(:final message):
                          return Center(child: Text("Error: $message"));
                        default:
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
                    },
                  ),
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
