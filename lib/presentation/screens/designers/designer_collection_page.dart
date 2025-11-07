import 'package:fashionista/data/models/designers/bloc/design_collection_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_event.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/screens/designers/add_design_collection_screen.dart';
import 'package:fashionista/presentation/screens/designers/widgets/design_collection_staggered_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerCollectionPage extends StatefulWidget {
  final Designer designer;
  const DesignerCollectionPage({super.key, required this.designer});

  @override
  State<DesignerCollectionPage> createState() => _DesignerCollectionPageState();
}

class _DesignerCollectionPageState extends State<DesignerCollectionPage> {
  late String currentUserId;

  @override
  void initState() {
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    context.read<DesignCollectionBloc>().add(
      LoadDesignCollectionsCacheFirstThenNetwork(widget.designer.uid),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocBuilder<DesignCollectionBloc, DesignCollectionState>(
        builder: (context, state) {
          switch (state) {
            case DesignCollectionLoading():
              return const Center(child: CircularProgressIndicator());
            case DesignCollectionsLoaded(:final designCollections):
              return DesignCollectionStaggeredView(
                designCollections: designCollections,
              );
            case DesignCollectionError(:final message):
              debugPrint(message);
              return Center(child: Text("Error: $message"));
            default:
              return const Center(child: Text("No design collection"));
          }
        },
      ),

      floatingActionButton: currentUserId == widget.designer.uid
          ? Hero(
              tag: 'add-design-collection-button',
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                elevation: 6,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddDesignCollectionScreen(),
                      ),
                    );

                    // if AddDesignCollectionScreen popped with "true", reload
                    if (result == true && mounted) {
                      context.read<DesignCollectionBloc>().add(
                        LoadDesignCollectionsCacheFirstThenNetwork(
                          widget.designer.uid,
                        ),
                      );
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.add, color: colorScheme.onPrimary),
                  ),
                ),
              ),
            )
          : null, // 👈 no FAB if not the designer
    );
  }
}
