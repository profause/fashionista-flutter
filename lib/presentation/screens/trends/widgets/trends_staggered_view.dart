import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TrendsStaggeredView extends StatelessWidget {
  final List<TrendFeedModel> items;
  const TrendsStaggeredView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MasonryGridView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          shrinkWrap: true,
          cacheExtent: 500,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final trend = items[index];
            return TrendInfoCardWidget(
              key: ValueKey(trend.uid),
              trendInfo: trend,
              aspectRatio: 3 / 4,
            );
          },
        ),
      ),
    );
  }
}
