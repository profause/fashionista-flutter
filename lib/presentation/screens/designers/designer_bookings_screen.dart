import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class DesignerBookingsScreen extends StatefulWidget {
  const DesignerBookingsScreen({super.key});

  @override
  State<DesignerBookingsScreen> createState() => _DesignerBookingsScreenState();
}

class _DesignerBookingsScreenState extends State<DesignerBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        foregroundColor: context.onCanvasText,
        backgroundColor: context.canvasBackground,
        title: Text(
          'My Bookings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: context.hairline)),
      ),
      body: const Placeholder(),
    );
  }
}