import 'dart:async';

import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/firebase/firebase_global_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchDebounce = Debouncer(const Duration(milliseconds: 350));
  late final UserBloc _userBloc;
  List<GlobalSearchResult> _searchIndex = [];
  List<GlobalSearchResult> _visibleResults = [];
  GlobalSearchCategory _selectedCategory = GlobalSearchCategory.all;
  String _query = '';
  String? _error;
  bool _isLoading = false;
  bool _isLoadingIndex = false;
  bool _hasLoadedIndex = false;

  @override
  void initState() {
    super.initState();
    _userBloc = context.read<UserBloc>();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: context.canvasBackground,
        elevation: 0,
        title: Hero(
          tag: 'search',
          child: Material(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 40,
              child: TextField(
                key: const Key("searchTextField"),
                keyboardType: TextInputType.text,
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search outfits, designers, styles...",
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
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_query.length >= 2) _buildCategoryFilters(),
          Expanded(child: _buildSearchBody()),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in GlobalSearchCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_categoryLabel(category)),
                selected: _selectedCategory == category,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                    _visibleResults = _filterResults(_searchIndex, _query);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBody() {
    if (_query.length < 2) {
      return Center(
        child: Icon(
          Icons.search,
          size: 40,
          color: context.mutedText,
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.secondaryLabel),
          ),
        ),
      );
    }

    if (_visibleResults.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: TextStyle(color: context.secondaryLabel),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _visibleResults.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.hairline),
      itemBuilder: (context, index) {
        final result = _visibleResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: CircleAvatar(
            backgroundColor: context.iconSubstrate,
            child: Icon(
              _categoryIcon(result.category),
              size: 20,
              color: context.secondaryLabel,
            ),
          ),
          title: Text(
            result.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.onCanvasText,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: result.subtitle.isEmpty
              ? null
              : Text(
                  result.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.secondaryLabel),
                ),
          trailing: Text(
            _categoryLabel(result.category),
            style: TextStyle(fontSize: 11, color: context.mutedText),
          ),
          onTap: result.route != null ||
                  result.category == GlobalSearchCategory.interests
              ? () => _openResult(result)
              : null,
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _error = null;
      if (query.length < 2) {
        _isLoading = false;
        _visibleResults = [];
      } else if (_hasLoadedIndex) {
        _visibleResults = _filterResults(_searchIndex, query);
      } else {
        _isLoading = true;
      }
    });

    if (query.length < 2 || _hasLoadedIndex || _isLoadingIndex) return;
    _searchDebounce.run(_loadSearchIndex);
  }

  Future<void> _loadSearchIndex() async {
    if (_isLoadingIndex || _hasLoadedIndex) return;
    final userId = _userBloc.state.uid;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Sign in to search your items';
      });
      return;
    }

    _isLoadingIndex = true;
    final result = await sl<FirebaseGlobalSearchService>().loadIndex(userId);
    if (!mounted) return;
    _isLoadingIndex = false;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = failure;
        });
      },
      (items) {
        setState(() {
          _searchIndex = items;
          _hasLoadedIndex = true;
          _visibleResults = _filterResults(items, _query);
          _isLoading = false;
        });
      },
    );
  }

  List<GlobalSearchResult> _filterResults(
    List<GlobalSearchResult> items,
    String query,
  ) {
    if (query.trim().length < 2) return [];

    final normalizedQuery = query.toLowerCase();
    return items
        .where(
          (item) =>
              (_selectedCategory == GlobalSearchCategory.all ||
                  item.category == _selectedCategory) &&
              item.searchableText.contains(normalizedQuery),
        )
        .toList();
  }

  void _openResult(GlobalSearchResult result) {
    if (result.category == GlobalSearchCategory.interests) {
      final query = result.title;
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
      setState(() {
        _query = query;
        _selectedCategory = GlobalSearchCategory.trends;
        _visibleResults = _filterResults(_searchIndex, query);
      });
      return;
    }

    if (result.category == GlobalSearchCategory.outfits) {
      context.go('/closet');
    } else if (result.route != null) {
      context.push(result.route!);
    }
  }

  String _categoryLabel(GlobalSearchCategory category) => switch (category) {
    GlobalSearchCategory.all => 'All',
    GlobalSearchCategory.interests => 'Interests',
    GlobalSearchCategory.trends => 'Trends',
    GlobalSearchCategory.users => 'Users',
    GlobalSearchCategory.designers => 'Designers',
    GlobalSearchCategory.outfits => 'Outfits',
    GlobalSearchCategory.workOrders => 'Work orders',
    GlobalSearchCategory.clients => 'Clients',
  };

  IconData _categoryIcon(GlobalSearchCategory category) => switch (category) {
    GlobalSearchCategory.interests => Icons.interests_outlined,
    GlobalSearchCategory.trends => Icons.trending_up,
    GlobalSearchCategory.users => Icons.person_outline,
    GlobalSearchCategory.designers => Icons.design_services_outlined,
    GlobalSearchCategory.outfits => Icons.checkroom_outlined,
    GlobalSearchCategory.workOrders => Icons.work_outline,
    GlobalSearchCategory.clients => Icons.people_outline,
    GlobalSearchCategory.all => Icons.search,
  };

  @override
  void dispose() {
    _searchDebounce.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer(this.delay);

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
