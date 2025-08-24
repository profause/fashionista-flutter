import 'package:flutter/material.dart';

class DesignerDetailsScreen extends StatefulWidget {
  const DesignerDetailsScreen({super.key});

  @override
  State<DesignerDetailsScreen> createState() => _DesignerDetailsScreenState();
}

class _DesignerDetailsScreenState extends State<DesignerDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(backgroundColor: colorScheme.surface);
  }
}
