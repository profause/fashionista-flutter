import 'package:flutter/material.dart';

class AddOrEditClosetItemsPage extends StatefulWidget {
  const AddOrEditClosetItemsPage({super.key});

  @override
  State<AddOrEditClosetItemsPage> createState() =>
      _AddOrEditClosetItemsPageState();
}

class _AddOrEditClosetItemsPageState extends State<AddOrEditClosetItemsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Add item to your closet',
          style: textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        elevation: 0,
      ),
    );
  }
}
