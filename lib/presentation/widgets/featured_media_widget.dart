import 'dart:async';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeaturedMediaWidget extends StatefulWidget {
  final List<FeaturedMediaModel> featuredMedia;

  const FeaturedMediaWidget({super.key, required this.featuredMedia});

  @override
  State<FeaturedMediaWidget> createState() => _FeaturedMediaWidgetState();
}

class _FeaturedMediaWidgetState extends State<FeaturedMediaWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  double _currentHeight = 250; // default initial height

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.featuredMedia.isNotEmpty) {
      _loadFirstImageSize();
    }
  }

  Future<void> _loadFirstImageSize() async {
    final size = widget.featuredMedia.first.aspectRatio;
    if (size != null && mounted) {
      setState(() {
        _currentHeight = _calculateDisplayHeight(size);
      });
    }
  }

  double _calculateDisplayHeight(double aspectRatio) {
    final screenWidth = MediaQuery.of(context).size.width;
    final newHeight = screenWidth / aspectRatio;
    return newHeight.clamp(180, 800);
  }

  Future<void> _updateHeightForIndex(int index) async {
    final size = widget.featuredMedia[index].aspectRatio;
    if (size != null && mounted) {
      setState(() {
        _currentHeight = _calculateDisplayHeight(size);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: _currentHeight,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.featuredMedia.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _updateHeightForIndex(index);
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.featuredMedia[index].url;
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.fill,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Center(child: Text('No Image')),
                  ),
                ),
              );
            },
          ),

          // 🔘 Page Indicator
          if (widget.featuredMedia.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.featuredMedia.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: _currentIndex == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
