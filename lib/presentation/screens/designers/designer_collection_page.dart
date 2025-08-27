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
    super.initState();
    //context.read<DesignCollectionBloc>().add(LoadDesignCollections(widget.designer.uid));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocProvider(
        create: (_) =>
            DesignCollectionBloc()
              ..add(LoadDesignCollections(widget.designer.uid)),
        child: BlocBuilder<DesignCollectionBloc, DesignCollectionState>(
          builder: (context, state) {
            switch (state) {
              case DesignCollectionLoading():
                return const Center(child: CircularProgressIndicator());
              case DesignCollectionsLoaded(:final designCollections):
                return DesignCollectionStaggeredView(
                  designCollections: designCollections,
                  onDesignCollectionTap: (value) {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.share),
                                title: const Text("Share"),
                                onTap: () {
                                  Navigator.pop(context);
                                  // TODO: implement share logic
                                  debugPrint("Share tapped for ${value.title}");
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.bookmark_border),
                                title: const Text("Bookmark"),
                                onTap: () {
                                  Navigator.pop(context);
                                  // TODO: implement bookmark logic
                                  debugPrint(
                                    "Bookmark tapped for ${value.title}",
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              // return ListView.builder(
              //   padding: const EdgeInsets.all(0),
              //   physics: const AlwaysScrollableScrollPhysics(),
              //   itemCount: designCollections.length,
              //   itemBuilder: (context, index) {
              //     final designCollection = designCollections[index];
              //     return DesignCollectionInfoCardWidget(
              //       designCollectionInfo: designCollection,
              //     );
              //   },
              // );
              case DesignCollectionError(:final message):
                debugPrint(message);
                return Center(child: Text("Error: $message"));
              default:
                return const Center(child: Text("No design collection"));
            }
          },
        ),
      ),

      floatingActionButton: currentUserId == widget.designer.uid
          ? Hero(
              tag: 'add-design-collection-button',
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                elevation: 6,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddDesignCollectionScreen(),
                      ),
                    );
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
