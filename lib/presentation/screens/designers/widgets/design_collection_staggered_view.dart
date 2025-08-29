import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'design_collection_info_card_widget.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';

class DesignCollectionStaggeredView extends StatelessWidget {
  final List<DesignCollectionModel> designCollections;

  const DesignCollectionStaggeredView({
    super.key,
    required this.designCollections,
  });

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
        itemCount: designCollections.length,
        itemBuilder: (context, index) {
          final designCollection = designCollections[index];
          // 👇 Assign different aspect ratios randomly for variety
          final aspectRatioOptions = [16 / 9, 4 / 5, 1 / 1];
          final aspectRatio =
              aspectRatioOptions[random.nextInt(aspectRatioOptions.length)];

          return DesignCollectionInfoCardWidget(
            designCollectionInfo: designCollection,
            aspectRatio: aspectRatio,
          );
        },
      ),
    );
  }
}
