import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    return Scaffold(
      body: Stack(
        children: [
          // Persistent status bar background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top,
              color: Colors.white, // Your desired status bar color
            ),
          ),
          // Main content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                snap: true,
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent, // Make it transparent
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
                centerTitle: centerTitle,
                title: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: actions,
              ),
              SliverToBoxAdapter(child: body),
            ],
          ),
        ],
      ),
    );
  }
}
