import 'package:fashionista/data/models/designers/bloc/design_collection_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerCollectionPage extends StatefulWidget {
  final Designer designer;
  const DesignerCollectionPage({super.key, required this.designer});

  @override
  State<DesignerCollectionPage> createState() => _DesignerCollectionPageState();
}

class _DesignerCollectionPageState extends State<DesignerCollectionPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocProvider(
      create: (_) => DesignCollectionBloc(),
      child: BlocBuilder<DesignCollectionBloc, DesignCollectionState>(
        builder: (context, state) {
          switch (state) {
            case DesignCollectionLoading():
              return const Center(child: CircularProgressIndicator());
            case DesignCollectionError(:final message):
              return Center(child: Text("Error: $message"));
            default:
              return const Center(child: Text("No design collection"));
          }
        },
      ),
    );
  }
}
