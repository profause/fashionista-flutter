import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:flutter/material.dart';

class TrendDetailsScreen extends StatefulWidget {
  final TrendFeedModel trendInfo;
  final int initialIndex;
  const TrendDetailsScreen({
    super.key,
    required this.trendInfo,
    required this.initialIndex,
  });

  @override
  State<TrendDetailsScreen> createState() => _TrendDetailsScreenState();
}

class _TrendDetailsScreenState extends State<TrendDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          '',
          style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
          color: colorScheme.primary
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(child: SingleChildScrollView()),
    );
  }
}
