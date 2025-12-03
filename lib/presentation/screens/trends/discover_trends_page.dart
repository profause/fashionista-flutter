import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trends_staggered_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

class DiscoverTrendsPage extends StatefulWidget {
  const DiscoverTrendsPage({super.key});

  @override
  State<DiscoverTrendsPage> createState() => _DiscoverTrendsPageState();
}

class _DiscoverTrendsPageState extends State<DiscoverTrendsPage> with TickerProviderStateMixin<DiscoverTrendsPage> {
  late AnimationController _hideFabAnimation;

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _hideFabAnimation = AnimationController(vsync: this, duration: kThemeAnimationDuration);
    context.read<TrendBloc>().add(const LoadTrendsCacheFirst(limit: 10));
    _hideFabAnimation.forward();
  }

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    return NotificationListener(
      onNotification: _handleScrollNotification,
      child: Scaffold(
        body: BlocListener<TrendBloc, TrendBlocState>(
          listener: (context, state) {
            if (state is TrendLoading) {
              _refreshKey.currentState?.show();
            }
          },
          child: RefreshIndicator(
            key: _refreshKey,
            onRefresh: () async {
              final bloc = context.read<TrendBloc>();
              bloc.add(const LoadTrendsCacheFirst(limit: 10));
              await bloc.stream.firstWhere((state) => state is! TrendLoading);
            },
            child: CustomScrollView(
              slivers: [
                BlocBuilder<TrendBloc, TrendBlocState>(
                  builder: (context, state) {
                    return ValueListenableBuilder<Box<TrendFeedModel>>(
                      valueListenable: sl<HiveTrendService>().itemListener(),
                      builder: (context, box, _) {
                        final trends = box.values.toList()
                          ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      
                        if (trends.isEmpty) {
                          // if (state is TrendLoading) {
                          //   return const SliverToBoxAdapter(
                          //     child: Center(child: CircularProgressIndicator()),
                          //   );
                          // }
                          return const SliverToBoxAdapter(
                            child: Center(child: Text("No trends found")),
                          );
                        }
      
                        return TrendsStaggeredView(items: trends);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: _hideFabAnimation,
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            onPressed: () => context.push('/trends-new'),
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _hideFabAnimation.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
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
