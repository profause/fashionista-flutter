import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:flutter/material.dart';

class DesignCollectionDetailsScreen extends StatefulWidget {
  final DesignCollectionModel designCollection;
  const DesignCollectionDetailsScreen({super.key, required this.designCollection});

  @override
  State<DesignCollectionDetailsScreen> createState() => _DesignCollectionDetailsScreenState();
}

class _DesignCollectionDetailsScreenState extends State<DesignCollectionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}