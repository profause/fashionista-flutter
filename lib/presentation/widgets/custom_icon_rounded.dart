import 'package:flutter/material.dart';

class CustomIconRounded extends StatelessWidget {
  final IconData icon;
  final double? size;
  const CustomIconRounded({
    super.key,
    required this.icon, 
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[300], // background color
      shape: const CircleBorder(),
     // borderRadius: BorderRadius.circular(size! / 2), // makes it round
      child: InkWell(
        borderRadius: BorderRadius.circular(50), // ripple matches shape
        child: Padding(
          padding: EdgeInsets.all(6), // space around icon
          child: Icon(icon, size: size),
        ),
      ),
    );
  }
}
