import 'package:flutter/material.dart';

class FullscreenGalleryWidget extends StatefulWidget {
  final List<String> images; // list of image URLs
  final int initialIndex;

  const FullscreenGalleryWidget({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullscreenGalleryWidget> createState() => _FullscreenGalleryWidgetState();
}

class _FullscreenGalleryWidgetState extends State<FullscreenGalleryWidget> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final imageUrl = widget.images[index];
                return Center(
                  child: Hero(
                    tag: imageUrl,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              color: Colors.white, size: 80),
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
              children: List.generate(widget.images.length, (index) {
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
              }),
            ),
          ),
        ],
      ),
    );
  }
}
