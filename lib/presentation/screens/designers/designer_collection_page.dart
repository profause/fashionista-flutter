import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:flutter/material.dart';

class DesignerCollectionPage extends StatefulWidget {
  final Designer designer;
  const DesignerCollectionPage({super.key, required this.designer});


  @override
  State<DesignerCollectionPage> createState() => _DesignerCollectionPageState();
}

class _DesignerCollectionPageState extends State<DesignerCollectionPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}