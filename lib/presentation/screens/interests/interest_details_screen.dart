import 'dart:async';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/firebase/firebase_fashion_interest_service.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trends_staggered_view.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';

class InterestDetailsScreen extends StatefulWidget {
  /// Optional search term to prefill when opened (e.g. from a trend tag).
  final String? initialQuery;

  const InterestDetailsScreen({super.key, this.initialQuery});

  @override
  State<InterestDetailsScreen> createState() => _InterestDetailsScreenState();
}

class _InterestDetailsScreenState extends State<InterestDetailsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchDebounce = Debouncer(const Duration(milliseconds: 350));

  bool _isLoading = false;
  String _query = '';
  List<FashionInterestModel> _interests = [];
  List<TrendFeedModel> _trends = [];

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
    }
    _searchFocusNode.requestFocus();
    if (initialQuery.isNotEmpty) {
      _runSearch(initialQuery);
    }
  }

  @override
  void dispose() {
    _searchDebounce.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
                  hintText: "Search Interests...",
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
      body: _buildBody(context),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce.cancel();
    _searchDebounce.run(() => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _query = '';
        _interests = [];
        _trends = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _query = query;
      _isLoading = true;
    });

    final interestsResult = await sl<FirebaseFashionInterestService>()
        .searchInterestsByName(query);
    final trendsResult = await sl<FirebaseTrendsService>().fetchTrendsByTag(
      query,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _interests = interestsResult.getOrElse(() => <FashionInterestModel>[]);
      _trends = trendsResult.getOrElse(() => <TrendFeedModel>[]);
    });
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty) {
      return const PageEmptyWidget(
        title: 'Search interests',
        subtitle: 'Find interests and trends by name or tag.',
        icon: Icons.search,
        iconSize: 56,
        fontSize: 16,
      );
    }

    if (_interests.isEmpty && _trends.isEmpty) {
      return PageEmptyWidget(
        title: 'No results for "$_query"',
        subtitle: 'Try a different interest or tag.',
        icon: Icons.search_off,
        iconSize: 56,
        fontSize: 16,
      );
    }

    return CustomScrollView(
      slivers: [
        if (_interests.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Interests', top: 16),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: context.hairline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              interest.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.onCanvasText,
                              ),
                            ),
                            if (interest.numberOfPosts > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '· ${interest.numberOfPosts}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.placeholderText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        if (_trends.isNotEmpty) ...[
          SliverToBoxAdapter(child: _sectionTitle(context, 'Trends')),
          TrendsStaggeredView(items: _trends),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    double top = 20,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: context.onCanvasText,
        ),
      ),
    );
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
