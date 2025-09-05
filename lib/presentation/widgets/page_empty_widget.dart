import 'package:flutter/material.dart';

class PageEmptyWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final double? iconSize;
  final double? fontSize;
  final IconData? icon;

  const PageEmptyWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconSize = 72,
    this.fontSize = 20,
  });

  @override
  State<PageEmptyWidget> createState() => _PageEmptyWidgetState();
}

class _PageEmptyWidgetState extends State<PageEmptyWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: -30.0, end: 0.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: value == 0 ? 1 : 0,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: theme.colorScheme.primary.withValues(alpha: 1),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: .8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
