import 'package:flutter/material.dart';

/// Post caption drawn over a bottom gradient, shared by the image carousel and
/// the video hero so a post looks the same whichever media it carries.
class FeaturedMediaCaption extends StatelessWidget {
  final String text;

  const FeaturedMediaCaption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 112,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.70),
              Colors.black.withValues(alpha: 0.35),
              Colors.transparent,
            ],
          ),
        ),
        child: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.3,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
