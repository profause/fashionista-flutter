import 'package:flutter/material.dart';

class FadeTitleSliverAppBar extends StatefulWidget {
  final String title;
  final double expandedHeight;
  final Widget? background;
  final ScrollController? controller;

  const FadeTitleSliverAppBar({
    super.key,
    required this.title,
    this.expandedHeight = 200,
    this.background,
    this.controller,
  });

  @override
  State<FadeTitleSliverAppBar> createState() => _FadeTitleSliverAppBarState();
}

class _FadeTitleSliverAppBarState extends State<FadeTitleSliverAppBar> {
  late ScrollController _scrollController;
  double _titleOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_updateOpacity);
  }

  void _updateOpacity() {
    double offset = _scrollController.offset;
    setState(() {
      _titleOpacity = (offset / 80).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      backgroundColor: colorScheme.onPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: widget.expandedHeight,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Opacity(
          opacity: _titleOpacity,
          child: Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        background:
            widget.background ??
            Container(
              color: colorScheme.onPrimary,
              alignment: Alignment.center,
              child: Text(widget.title, style: const TextStyle(fontSize: 24)),
            ),
      ),
    );
  }
}
