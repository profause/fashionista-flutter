import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewOnlyImageWidget extends StatelessWidget {
  final String imagePath; // can be a URL or local file path
  final double height;
  final double width;
  final double borderRadius;

  const ViewOnlyImageWidget({
    super.key,
    required this.imagePath,
    this.height = 100,
    this.width = 100,
    this.borderRadius = 12,
  });

  bool get _isNetworkImage {
    return imagePath.startsWith("http://") || imagePath.startsWith("https://");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: _isNetworkImage
              ? CachedNetworkImage(
                  imageUrl: imagePath,
                  fit: BoxFit.cover,
                  height: height,
                  width: width,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 40),
                )
              : Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  height: height,
                  width: width,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 40),
                ),
        ),
      ],
    );
  }
}
