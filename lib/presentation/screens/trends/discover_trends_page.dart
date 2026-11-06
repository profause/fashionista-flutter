import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_state.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_feed_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DiscoverTrendsPage extends StatefulWidget {
  const DiscoverTrendsPage({super.key});

  @override
  State<DiscoverTrendsPage> createState() => _DiscoverTrendsPageState();
}

class _DiscoverTrendsPageState extends State<DiscoverTrendsPage>
    with TickerProviderStateMixin<DiscoverTrendsPage> {
  /// How close to the end the viewport must be before the next page is asked
  /// for.
  static const double _loadMoreThreshold = 300;

  late AnimationController _hideFabAnimation;

  /// Set when a page was requested and cleared when it lands.
  ///
  /// Scroll notifications arrive faster than the bloc can flip `isLoadingMore`,
  /// so this stops one flick of the finger from queueing several pages.
  bool _pendingLoadMore = false;

  @override
  void initState() {
    super.initState();
    _hideFabAnimation = AnimationController(
      vsync: this,
      duration: kThemeAnimationDuration,
    );
    context.read<TrendFeedBloc>().add(const TrendFeedOpened());
    _hideFabAnimation.forward();
  }

  @override
  void dispose() {
    // The controller must be disposed before the ticker provider mixin,
    // otherwise the still-running ticker is reported as a leak.
    _hideFabAnimation.dispose();
    super.dispose();
  }

  void _requestMore() {
    if (!mounted || _pendingLoadMore) return;

    final state = context.read<TrendFeedBloc>().state;
    if (state.isLoadingInitial || state.isLoadingMore) return;
    if (!state.hasMore || state.loadMoreError != null) return;

    _pendingLoadMore = true;
    context.read<TrendFeedBloc>().add(const TrendFeedLoadMore());
  }

  Future<void> _refresh() async {
    final bloc = context.read<TrendFeedBloc>();

    // Resolve once the refresh produced an answer: a network page, or an error.
    // The cache-first paint is not an answer.
    final done = bloc.stream
        .firstWhere(
          (state) =>
              !state.fromCache ||
              state.initialError != null ||
              state.loadMoreError != null,
        )
        .timeout(const Duration(seconds: 10), onTimeout: () => bloc.state);

    bloc.add(const TrendFeedRefresh());
    await done;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: _handleScrollNotification,
      child: Scaffold(
        body: BlocConsumer<TrendFeedBloc, TrendFeedState>(
          listener: (context, state) {
            if (!state.isLoadingMore) _pendingLoadMore = false;
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: _buildSlivers(context, state),
              ),
            );
          },
        ),
        floatingActionButton: ScaleTransition(
          scale: _hideFabAnimation,
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            backgroundColor: context.accent,
            foregroundColor: Colors.white,
            onPressed: () => context.push('/trends-new'),
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context, TrendFeedState state) {
    if (state.isLoadingInitial && state.items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _FeedMessage(
            title: state.initialError != null
                ? 'Could not load trends'
                : 'No trends found',
            subtitle: state.initialError,
            onRetry: state.initialError == null
                ? null
                : () =>
                      context.read<TrendFeedBloc>().add(const TrendFeedRetry()),
          ),
        ),
      ];
    }

    return [
      const SliverToBoxAdapter(child: SizedBox(height: 4)),
      TrendFeedSliver(items: state.items),
      TrendFeedFooter(
        isLoadingMore: state.isLoadingMore,
        error: state.loadMoreError,
        onRetry: () =>
            context.read<TrendFeedBloc>().add(const TrendFeedRetry()),
      ),
      // Only arm the sentinel when another page is actually available: it fires
      // on build, so leaving it armed after a failure would hammer the backend.
      if (state.hasMore && !state.isLoadingMore && state.loadMoreError == null)
        TrendFeedSentinel(
          threshold: _loadMoreThreshold,
          onVisible: _requestMore,
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      // Notifications reaching this listener come from the feed's own
      // CustomScrollView, so `extentAfter` is its real remaining extent.
      if (notification.metrics.axis == Axis.vertical &&
          notification.metrics.extentAfter < _loadMoreThreshold) {
        _requestMore();
      }

      if (notification is UserScrollNotification) {
        final UserScrollNotification userScroll = notification;
        switch (userScroll.direction) {
          case ScrollDirection.forward:
            if (userScroll.metrics.maxScrollExtent !=
                userScroll.metrics.minScrollExtent) {
              _hideFabAnimation.forward();
            }
            break;
          case ScrollDirection.reverse:
            if (userScroll.metrics.maxScrollExtent !=
                userScroll.metrics.minScrollExtent) {
              _hideFabAnimation.reverse();
            }
            break;
          case ScrollDirection.idle:
            break;
        }
      }
    }
    return false;
  }
}

class _FeedMessage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const _FeedMessage({required this.title, this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall!.copyWith(fontSize: 15),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.mutedText),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
