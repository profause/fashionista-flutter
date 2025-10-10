import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class AnimatedTitle extends StatefulWidget {
  const AnimatedTitle({super.key});

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final String _title = "Fashionista";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_title.length, (index) {
        final char = _title[index];

        // set each character to appear staggered
        final intervalStart = index / _title.length;
        final intervalEnd = (index + 1) / _title.length;

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.5, 0), // from right
              end: Offset.zero,
            ).animate(animation),
            child: Text(
              char,
              style: AppTheme.appTitleStyle.copyWith(
                color: AppTheme.black,),
            ),
          ),
        );
      }),
    );
  }
}
