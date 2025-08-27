import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:flutter/material.dart';

class AddDesignCollectionScreen extends StatefulWidget {
  final DesignCollectionModel? designCollection;

  const AddDesignCollectionScreen({super.key, this.designCollection});

  @override
  State<AddDesignCollectionScreen> createState() => _AddDesignCollectionScreenState();
}

class _AddDesignCollectionScreenState extends State<AddDesignCollectionScreen> {

  @override
  void initState() {
    if (widget.designCollection == null) {
      setState(() {
        //widget.designCollection = DesignCollectionModel.empty();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Add Design Collection'),
        elevation: 0,
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
      ),
    );
  }
}