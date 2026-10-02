import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class MyMeasurementScreen extends StatefulWidget {
  const MyMeasurementScreen({super.key});

  @override
  State<MyMeasurementScreen> createState() => _MyMeasurementScreenState();
}

class _MyMeasurementScreenState extends State<MyMeasurementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: context.onCanvasText,
        backgroundColor: context.cardSurface,
        title: const Text('My Measurement'),
        elevation: 0,
      ),
      body: const Placeholder(),
    );
  }
}