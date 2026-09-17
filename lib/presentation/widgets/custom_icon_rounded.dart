import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class CustomIconRounded extends StatelessWidget {
  final IconData icon;
  final double? size;
  const CustomIconRounded({super.key, required this.icon, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.iconSubstrate, // neutral icon tile background
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(50), // ripple matches shape
        child: Padding(
          padding: EdgeInsets.all(6), // space around icon
          child: Icon(
            icon,
            size: size,
            color: context.secondaryLabel,
          ),
        ),
      ),
    );
  }
}