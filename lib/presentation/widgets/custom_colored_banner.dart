import 'dart:math';
import 'package:flutter/material.dart';

class CustomColoredBanner extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final double height;
  final double borderRadius;

  const CustomColoredBanner({
    super.key,
    required this.text,
    this.textStyle,
    this.height = 150,
    this.borderRadius = 0,
  });

  @override
  State<CustomColoredBanner> createState() => _CustomColoredBannerState();
}

class _CustomColoredBannerState extends State<CustomColoredBanner> {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = _getRandomColor(); // pick once per widget instance
  }

  Color _getRandomColor() {
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      //margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.text,
          style: widget.textStyle ??
              Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                  ),
        ),
      ),
    );
  }
}
