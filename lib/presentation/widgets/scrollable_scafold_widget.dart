import 'package:flutter/material.dart';
import 'package:fashionista/core/theme/theme_extensions.dart';

class ScrollableScafoldWidget extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool centerTitle;

  const ScrollableScafoldWidget({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scrollController = ScrollController();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          Theme.of(context).fadeSliverAppBar(
            title: 'Profile',
            expandedHeight: 48,
            controller: scrollController,
            background: Container(
              color: colorScheme.onPrimary,
              alignment: Alignment.center,
              child: const Text(
                'Profile',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          SliverToBoxAdapter(child: body),
        ],
      ),
    );
  }
}
