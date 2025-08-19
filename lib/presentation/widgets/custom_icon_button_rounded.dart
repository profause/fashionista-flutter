import 'package:flutter/material.dart';

class CustomIconButtonRounded extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double? size;
  const CustomIconButtonRounded({
    super.key,
    required this.onPressed,
    required this.icon, 
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[300], // background color
      shape: const CircleBorder(), // makes it round
      child: InkWell(
        borderRadius: BorderRadius.circular(50), // ripple matches shape
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(4), // space around icon
          child: Icon(icon, size: size),
        ),
      ),
    );
  }
}
