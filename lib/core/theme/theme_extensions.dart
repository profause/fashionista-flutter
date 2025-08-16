// theme_extensions.dart
import 'package:fashionista/presentation/widgets/fade_title_sliver_app_bar.dart';
import 'package:flutter/material.dart';

extension AppBarThemeExtensions on ThemeData {
  Widget fadeSliverAppBar({
    required String title,
    double expandedHeight = 200,
    Widget? background,
    ScrollController? controller,
  }) {
    return FadeTitleSliverAppBar(
          title: title,
          expandedHeight: expandedHeight,
          background: background,
          controller: controller,
        );
  }
}
