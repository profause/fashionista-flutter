import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Lazy two-column masonry feed.
///
/// A real sliver (unlike the old shrink-wrapped `MasonryGridView`) so only the
/// visible cards are built and the scroll view gets a true extent.
class TrendFeedSliver extends StatelessWidget {
  final List<TrendFeedModel> items;

  const TrendFeedSliver({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childCount: items.length,
        itemBuilder: (context, index) {
          final trend = items[index];
          return TrendInfoCardWidget(
            key: ValueKey(trend.uid),
            trendInfo: trend,
            aspectRatio: 3 / 4,
          );
        },
      ),
    );
  }
}

/// Zero-height sliver that fires [onVisible] once per build, when the end of
/// the feed is actually near.
///
/// Being built is only a hint: on the first layout the masonry grid has no
/// measured extent yet, so this sliver can be built while the user is still at
/// the top. The post-frame check re-reads the real scroll position, and feeds
/// shorter than the screen pass it because `extentAfter` is then zero.
class TrendFeedSentinel extends StatefulWidget {
  final VoidCallback onVisible;

  /// How close to the end the viewport must be before a page is fetched.
  final double threshold;

  const TrendFeedSentinel({
    super.key,
    required this.onVisible,
    this.threshold = 300,
  });

  @override
  State<TrendFeedSentinel> createState() => _TrendFeedSentinelState();
}

class _TrendFeedSentinelState extends State<TrendFeedSentinel> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduled = false;

        // Nearest Scrollable is the feed's own CustomScrollView, not the Home
        // tab's NestedScrollView.
        final position = Scrollable.maybeOf(context)?.position;
        if (position != null &&
            position.hasContentDimensions &&
            position.extentAfter > widget.threshold) {
          return;
        }

        widget.onVisible();
      });
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

/// Bottom of the feed: a small spinner, or a retry after a failed page.
class TrendFeedFooter extends StatelessWidget {
  final bool isLoadingMore;
  final String? error;
  final VoidCallback onRetry;

  const TrendFeedFooter({
    super.key,
    required this.isLoadingMore,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load more',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (!isLoadingMore) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
