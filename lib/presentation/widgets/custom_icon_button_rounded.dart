import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class CustomIconButtonRounded extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData iconData;
  final double? size;
  final Widget? icon;
  final Color? backgroundColor;
  const CustomIconButtonRounded({
    super.key,
    required this.onPressed,
    this.icon,
    this.size = 24,
    required this.iconData,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ??
          context.iconSubstrate, // neutral icon tile background
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(50), // ripple matches shape
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(6), // space around icon
          child: IconTheme(
            data: IconThemeData(color: context.secondaryLabel, size: size),
            child: icon ?? Icon(iconData, size: size),
          ),
        ),
      ),
    );
  }
}