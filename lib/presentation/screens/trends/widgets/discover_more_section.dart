import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget.dart';
import 'package:flutter/material.dart';

/// Horizontal rail of trends sharing at least one tag with the post on screen.
///
/// The section hides itself when the post has no tags or nothing matches, so a
/// lone post never gets an empty heading.
class DiscoverMoreSection extends StatefulWidget {
  /// Tags of the post being viewed. Comma-joined values are also accepted.
  final List<String> tags;

  /// The post on screen; it must not recommend itself.
  final String? excludeTrendId;

  /// How many recent documents to scan in Firestore.
  final int scanLimit;

  /// Maximum number of cards to show.
  final int maxResults;

  final double cardWidth;

  const DiscoverMoreSection({
    super.key,
    required this.tags,
    this.excludeTrendId,
    this.scanLimit = 100,
    this.maxResults = 12,
    this.cardWidth = 150,
  });

  @override
  State<DiscoverMoreSection> createState() => _DiscoverMoreSectionState();
}

class _DiscoverMoreSectionState extends State<DiscoverMoreSection> {
  List<TrendFeedModel> _trends = const [];
  String _loadedSignature = '';

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant DiscoverMoreSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  static List<String> _normalize(Iterable<String> tags) {
    final seen = <String>{};
    for (final raw in tags) {
      for (final part in raw.split(',')) {
        final tag = part.trim().toLowerCase();
        if (tag.isNotEmpty) seen.add(tag);
      }
    }
    return seen.toList(growable: false);
  }

  String _signature() =>
      '${_normalize(widget.tags).join('|')}#${widget.excludeTrendId ?? ''}';

  void _sync() {
    final signature = _signature();
    if (signature == _loadedSignature) return;
    _loadedSignature = signature;
    _load(signature);
  }

  Future<void> _load(String signature) async {
    final tags = _normalize(widget.tags);

    if (tags.isEmpty) {
      if (!mounted) return;
      if (_trends.isNotEmpty) setState(() => _trends = const []);
      return;
    }

    final result = await sl<FirebaseTrendsService>().fetchTrendsByTags(
      tags,
      limit: widget.scanLimit,
      maxResults: widget.maxResults,
    );

    // Tags can change (or the screen can close) while the fetch is in flight.
    if (!mounted || signature != _loadedSignature) return;

    setState(() {
      _trends = result.fold(
        (_) => const <TrendFeedModel>[],
        (trends) => trends
            .where((trend) => trend.uid != widget.excludeTrendId)
            .toList(growable: false),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_trends.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final cardHeight = widget.cardWidth * 4 / 3;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, thickness: 1, color: context.hairline),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Text(
              'Discover more',
              style: textTheme.titleSmall?.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _trends.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final trend = _trends[index];
                return SizedBox(
                  width: widget.cardWidth,
                  child: TrendInfoCardWidget(
                    key: ValueKey('discover-more-${trend.uid}'),
                    trendInfo: trend,
                    aspectRatio: 3 / 4,
                    respectMediaAspectRatio: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
