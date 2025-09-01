import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
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
              onPressed: () {},
              icon: Icon(Icons.delete),
              color: Colors.white,
            ),
            //const SizedBox(width: 4,),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.edit),
              color: Colors.white,
            ),
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
                          widget.designCollection.featuredImages[index];
                      return Center(
                        child: Hero(
                          tag: widget.designCollection.featuredImages.first,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
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
}
