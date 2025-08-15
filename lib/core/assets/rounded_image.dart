import 'package:flutter/material.dart';

class RoundedImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final bool isAsset;

  const RoundedImage({
    super.key,
    required this.imageUrl,
    this.width = 150,
    this.height = 150,
    this.borderRadius = 16,
    this.isAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: isAsset
              ? AssetImage(imageUrl) as ImageProvider
              : NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
