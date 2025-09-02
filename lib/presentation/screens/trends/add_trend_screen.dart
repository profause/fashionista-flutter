import 'package:flutter/material.dart';

class AddTrendScreen extends StatefulWidget {
  const AddTrendScreen({super.key});

  @override
  State<AddTrendScreen> createState() => _AddTrendScreenState();
}

class _AddTrendScreenState extends State<AddTrendScreen> {
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
          'Start a trend',
          style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
          color: colorScheme.primary
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(child: SingleChildScrollView()),
    );
  }
}
