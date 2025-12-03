import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_flutter/image/cld_image_widget_configuration.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_event.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/services/firebase/firebase_design_collection_service.dart';
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
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _settingsBloc = context.read<SettingsBloc>();
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
                      final imageUrl = widget
                          .designCollection
                          .featuredImages[index]
                          .thumbnailUrl;
                      return Center(
                        child: Hero(
                          tag: widget.designCollection.featuredImages.first,
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CldImageWidget(
                              key: ValueKey(imageUrl),
                              cloudinary: Cloudinary.fromConfiguration(
                                CloudinaryConfig.fromUri(
                                  appConfig.get('cloudinary_url'),
                                ),
                              ),
                              publicId:
                                  '${widget.designCollection.featuredImages[index].uid}',
                              configuration: CldImageWidgetConfiguration(
                                cache: true,
                              ),
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              fit: BoxFit.fill,
                              placeholderFadeInDuration: const Duration(
                                milliseconds: 150,
                              ),
                              errorBuilder: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              transformation:
                                  Transformation().addTransformation(
                                    _settingsBloc.state.imageQuality == 'HD'
                                        ? 'q_100' //'q_auto:best'
                                        : 'q_auto:good',
                                  )..resize(
                                    Resize.fill().aspectRatio(
                                      widget
                                          .designCollection
                                          .featuredImages[index]
                                          .aspectRatio,
                                    ),
                                  ),
                            ),

                            // CachedNetworkImage(
                            //   imageUrl: imageUrl!,
                            //   fit: BoxFit.cover,
                            //   errorListener: (value) {

                            //   },
                            //   placeholder: (context, url) => const Center(
                            //     child: SizedBox(
                            //       height: 18,
                            //       width: 18,
                            //       child: CircularProgressIndicator(
                            //         strokeWidth: 2,
                            //       ),
                            //     ),
                            //   ),
                            //   errorWidget: (context, url, error) {
                            //     return const CustomColoredBanner(
                            //       text: 'No Image',
                            //     );
                            //   },
                            // ),
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
                        runSpacing: 8, // 👈 reduced padding
                        children: widget.designCollection.tags!.isEmpty
                            ? [SizedBox(height: 1)]
                            : widget.designCollection.tags!
                                  .split('|')
                                  .where(
                                    (tag) => tag.trim().isNotEmpty,
                                  ) // ✅ only keep non-empty tags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      padding: EdgeInsets
                                          .zero, // remove extra padding
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                  .toList(),
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
      showLoadingDialog(context);
      final futures = designCollection.featuredImages
          .where((e) => e.uid != null) // filter null UID
          .map(
            (e) => sl<FirebaseDesignCollectionService>()
                .deleteDesignCollectionImage(e.uid!),
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
      dismissLoadingDialog(context);
      context.read<DesignCollectionBloc>().add(
        DeleteDesignCollection(designCollection),
      );

      context.read<DesignCollectionBloc>().add(
        LoadDesignCollectionsCacheFirstThenNetwork(designCollection.createdBy),
      );
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      dismissLoadingDialog(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
