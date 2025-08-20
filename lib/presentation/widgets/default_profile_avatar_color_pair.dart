import 'package:flutter/material.dart';

class DefaultProfileAvatarColorPair {
  static const List<Map<String, Color>> colors = [
    {
      "background": Color(0xFFC8E6C9), // Light Green 100
      "foreground": Color(0xFF2E7D32), // Green 800
    },
    {
      "background": Color(0xFFBBDEFB), // Light Blue 100
      "foreground": Color(0xFF1565C0), // Blue 800
    },
    {
      "background": Color(0xFFFFCDD2), // Red 100
      "foreground": Color(0xFFC62828), // Red 800
    },
    {
      "background": Color(0xFFFFF9C4), // Yellow 100
      "foreground": Color(0xFFF9A825), // Yellow 800
    },
    {
      "background": Color(0xFFD1C4E9), // Deep Purple 100
      "foreground": Color(0xFF4527A0), // Deep Purple 800
    },
    {
      "background": Color(0xFFFFE0B2), // Orange 100
      "foreground": Color(0xFFEF6C00), // Orange 800
    },
    {
      "background": Color(0xFFB2DFDB), // Teal 100
      "foreground": Color(0xFF00695C), // Teal 800
    },
    {
      "background": Color(0xFFDCEDC8), // Lime 100
      "foreground": Color(0xFF558B2F), // Lime 800
    },
  ];

  /// Get a color pair based on user's unique key (e.g., uid, email, name)
  static Map<String, Color> getColorPair(String key) {
    final index = key.hashCode.abs() % colors.length;
    return colors[index];
  }
}
