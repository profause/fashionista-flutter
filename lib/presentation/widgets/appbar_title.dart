import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  final String title;

  const AppBarTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      key: const ValueKey("appBarTitle"),
      style: textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 20
      ),
    );
  }
}
