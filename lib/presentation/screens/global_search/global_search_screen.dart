import 'dart:async';

import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/firebase/firebase_global_search_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/designer_compact_card_widget.dart';
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
  List<GlobalSearchResult> _initialResults = [];
  List<GlobalSearchResult> _visibleResults = [];
  String _initialResultsTitle = 'Suggested for you';
  GlobalSearchCategory _selectedCategory = GlobalSearchCategory.all;
  String _query = '';
  String? _error;
  bool _isLoading = false;
  bool _isLoadingIndex = false;
  bool _hasLoadedIndex = false;
  bool _hasCachedInitialResults = false;

  @override
  void initState() {
    super.initState();
    _userBloc = context.read<UserBloc>();
    _searchFocusNode.requestFocus();
    _loadInitialContent();
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
                  _cacheVisibleResults();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBody() {
    if (_query.length < 2) {
      if (_visibleResults.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                _initialResultsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.onCanvasText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: _buildResultSections(_visibleResults)),
          ],
        );
      }

      if (_isLoadingIndex) {
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

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 40, color: context.mutedText),
            const SizedBox(height: 8),
            Text(
              'Search across Fashionista',
              style: TextStyle(color: context.secondaryLabel),
            ),
          ],
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

    return _buildResultSections(_visibleResults);
  }

  Widget _buildResultSections(List<GlobalSearchResult> results) {
    final sections = <GlobalSearchCategory, List<GlobalSearchResult>>{};
    for (final result in results) {
      sections.putIfAbsent(result.category, () => []).add(result);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final category = sections.keys.elementAt(index);
        final results = sections[category]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Text(
                      _categoryLabel(category),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.onCanvasText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${results.length}',
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (category == GlobalSearchCategory.designers)
                _buildDesignerResults(results)
              else if (category == GlobalSearchCategory.interests)
                _buildInterestResults(results)
              else
                ...results.map(_buildCategoryResult),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesignerResults(List<GlobalSearchResult> results) {
    final designers = results
        .map((result) => result.designer)
        .whereType<Designer>()
        .toList();
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: designers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => DesignerCompactCardWidget(
          key: ValueKey(designers[index].uid),
          designerInfo: designers[index],
        ),
      ),
    );
  }

  Widget _buildInterestResults(List<GlobalSearchResult> results) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final result in results)
            ActionChip(
              avatar: Icon(
                Icons.interests_outlined,
                size: 16,
                color: context.secondaryLabel,
              ),
              label: Text(result.title),
              onPressed: () => _openResult(result),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryResult(GlobalSearchResult result) {
    switch (result.category) {
      case GlobalSearchCategory.trends:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: CircleAvatar(
            backgroundColor: context.accent.withValues(alpha: 0.12),
            child: Icon(Icons.trending_up, color: context.accent),
          ),
          title: Text(result.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: result.subtitle.isEmpty ? null : Text(result.subtitle),
          onTap: result.route == null ? null : () => context.push(result.route!),
        );
      case GlobalSearchCategory.users:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: CircleAvatar(
            backgroundColor: context.iconSubstrate,
            child: Text(
              result.title.isEmpty ? '?' : result.title[0].toUpperCase(),
              style: TextStyle(color: context.onCanvasText),
            ),
          ),
          title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: result.subtitle.isEmpty ? null : Text(result.subtitle),
          onTap: result.route == null ? null : () => context.push(result.route!),
        );
      case GlobalSearchCategory.outfits:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go('/closet'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.checkroom_outlined, color: context.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.onCanvasText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (result.subtitle.isNotEmpty)
                            Text(
                              result.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.secondaryLabel),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: context.mutedText),
                  ],
                ),
              ),
            ),
          ),
        );
      case GlobalSearchCategory.workOrders:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(Icons.work_outline, color: context.secondaryLabel),
          title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: result.subtitle.isEmpty ? null : Text(result.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: result.route == null ? null : () => context.push(result.route!),
        );
      case GlobalSearchCategory.clients:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: CircleAvatar(
            backgroundColor: context.iconSubstrate,
            child: Icon(Icons.person_outline, color: context.secondaryLabel),
          ),
          title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: result.subtitle.isEmpty ? null : Text(result.subtitle),
          onTap: result.route == null ? null : () => context.push(result.route!),
        );
      case GlobalSearchCategory.all:
      case GlobalSearchCategory.interests:
      case GlobalSearchCategory.designers:
        return const SizedBox.shrink();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _error = null;
      if (query.length < 2) {
        _isLoading = false;
        _visibleResults = _initialResults;
      } else if (_hasLoadedIndex) {
        _visibleResults = _filterResults(_searchIndex, query);
      } else {
        _isLoading = true;
      }
    });

    if (query.length < 2 || _isLoadingIndex) return;
    if (_hasLoadedIndex) {
      _searchDebounce.run(_cacheVisibleResults);
    } else {
      _searchDebounce.run(_loadSearchIndex);
    }
  }

  Future<void> _loadInitialContent() async {
    final userId = _userBloc.state.uid;
    if (userId == null || userId.isEmpty) return;

    _isLoadingIndex = true;
    final service = sl<FirebaseGlobalSearchService>();
    final cachedResults = await service.loadCachedResults(userId);
    if (!mounted) return;

    if (cachedResults.isNotEmpty) {
      _hasCachedInitialResults = true;
      setState(() {
        _initialResults = cachedResults;
        _visibleResults = cachedResults;
        _initialResultsTitle = 'Recent results';
      });
    }

    _isLoadingIndex = false;
    await _loadSearchIndex();
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
        final suggestions = _initialResults.isEmpty && _query.length < 2
            ? sl<FirebaseGlobalSearchService>().pickRandomSuggestions(items)
            : _initialResults;
        setState(() {
          _searchIndex = items;
          _hasLoadedIndex = true;
          if (_query.length < 2) {
            _initialResults = suggestions;
            _visibleResults = suggestions;
            if (_initialResultsTitle != 'Recent results') {
              _initialResultsTitle = 'Suggested for you';
            }
          } else {
            _visibleResults = _filterResults(items, _query);
          }
          _isLoading = false;
        });
        if (_query.length >= 2) {
          _cacheVisibleResults();
        } else if (!_hasCachedInitialResults) {
          _cacheVisibleResults();
        }
      },
    );
  }

  Future<void> _cacheVisibleResults() async {
    final userId = _userBloc.state.uid;
    if (userId == null || userId.isEmpty || _visibleResults.isEmpty) return;
    await sl<FirebaseGlobalSearchService>().cacheResults(
      userId,
      _visibleResults,
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
