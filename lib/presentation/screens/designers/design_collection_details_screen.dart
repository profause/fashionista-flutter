import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_event.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/data/services/firebase/firebase_design_collection_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignCollectionDetailsScreen extends StatefulWidget {
  final DesignCollectionModel designCollection;
  final int initialIndex;
  const DesignCollectionDetailsScreen({
    super.key,
    required this.designCollection,
    required this.initialIndex,
  });

  @override
  State<DesignCollectionDetailsScreen> createState() =>
      _DesignCollectionDetailsScreenState();
}

class _DesignCollectionDetailsScreenState
    extends State<DesignCollectionDetailsScreen> {
  late PageController _controller;
  late int _currentIndex;
  bool showDetails = true;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.designCollection.title,
          style: textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (userId == widget.designCollection.createdBy) ...[
            IconButton(
              onPressed: () async {
                final canDelete = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Post'),
                    content: const Text(
                      'Are you sure you want to delete this post?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (canDelete == true) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false, // Prevent dismissing
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                  }

                  _deleteDesignCollection(widget.designCollection);
                }
              },
              icon: Icon(Icons.delete),
              color: Colors.white,
            ),
            //const SizedBox(width: 4,),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    showDetails = !showDetails;
                  }), //Navigator.pop(context, true),
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: widget.designCollection.featuredImages.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final imageUrl =
                          widget.designCollection.featuredImages[index].thumbnailUrl;
                      return Center(
                        child: Hero(
                          tag: widget.designCollection.featuredImages.first,
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                return const CustomColoredBanner(
                                  text: 'No Image',
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Dot indicators
                Positioned(
                  bottom: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.designCollection.featuredImages.length,
                      (index) {
                        final isActive = index == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isActive ? 20 : 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDetails) ...[
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.designCollection.description ?? '',
                    style: textTheme.bodyLarge!.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  if (widget.designCollection.tags != null) ...[
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          widget.designCollection.tags!.split('|').length,
                          (index) => Chip(
                            label: Text(
                              widget.designCollection.tags!.split('|')[index],
                            ),
                            padding: EdgeInsets.zero, // remove extra padding
                            visualDensity:
                                VisualDensity.compact, // tighter look
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteDesignCollection(
    DesignCollectionModel designCollection,
  ) async {
    try {
      // create a dynamic list of futures
      final List<Future<dartz.Either>> futures = designCollection.featuredImages
          .map(
            (e) => sl<FirebaseDesignCollectionService>()
                .deleteDesignCollectionImage(e.url!),
          )
          .toList();

      // also add delete by id
      futures.add(
        sl<FirebaseDesignCollectionService>().deleteDesignCollectionById(
          designCollection.uid!,
        ),
      );

      // wait for all and capture results
      final results = await Future.wait(futures);

      // handle each result
      for (final result in results) {
        result.fold(
          (failure) {
            // handle failure
            debugPrint("Delete failed: $failure");
          },
          (success) {
            // handle success
            debugPrint("Delete success: $success");
          },
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      context.read<DesignCollectionBloc>().add(
        LoadDesignCollectionsCacheFirstThenNetwork(designCollection.createdBy),
      );
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }
}
