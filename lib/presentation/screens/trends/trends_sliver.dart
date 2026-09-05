
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trends_staggered_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:sliver_tools/sliver_tools.dart';

List<String> hints = [
  "✨ Share your next fashion moment…",
  "👗 What’s trending in your world?",
  "🧵 Stitch your trend into the feed…",
  "🚀 Kick off the next big fashion vibe…",
  "🖋 Describe your style inspiration…",
  "🔥 Drop your hottest fashion trend…",
];

class TrendsSliver extends StatelessWidget {
  const TrendsSliver({super.key});

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    //final random = Random();

    return MultiSliver(
      children: [
        // BLoC + Hive list
        BlocBuilder<TrendBloc, TrendBlocState>(
          builder: (context, state) {
            return ValueListenableBuilder<Box<TrendFeedModel>>(
              valueListenable: sl<HiveTrendService>().itemListener(),
              builder: (context, box, _) {
                final trends = box.values.toList();
                trends.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

                return MultiSliver(
                  children: [
                    TrendsStaggeredView(items: trends),

                    if (state is TrendLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
