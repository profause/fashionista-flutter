import 'dart:math';

import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TrendsStaggeredView extends StatelessWidget {
  final List<TrendFeedModel> items;
  const TrendsStaggeredView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MasonryGridView.builder(
        padding: const EdgeInsets.only(top: 8),
        shrinkWrap: false,
        cacheExtent: 200,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final trend = items[index];
          // 👇 Assign different aspect ratios randomly for variety
          final aspectRatioOptions = [16 / 9, 4 / 5, 1 / 1, 3 / 2];
          final aspectRatio =
              aspectRatioOptions[random.nextInt(aspectRatioOptions.length)];

          return TrendInfoCardWidget(
            trendInfo: trend,
            aspectRatio: aspectRatio,
          );
        },
      ),
    );
  }
}
