import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GridThumbnailWidget extends StatefulWidget {
  final List<String> imageUrls;
  final double? size;
  final Function? onImageLoaded;

  const GridThumbnailWidget({
    super.key,
    required this.imageUrls,
    this.size = 140,
    this.onImageLoaded,
  });

  @override
  State<GridThumbnailWidget> createState() => _GridThumbnailWidgetState();
}

class _GridThumbnailWidgetState extends State<GridThumbnailWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  Uint8List? _thumbnailBytes;

  @override
  void didUpdateWidget(covariant GridThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      _thumbnailBytes = null; // regenerate if images change
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(
        pixelRatio: 1.0,
      ); // high resolution
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes != null) {
        setState(() {
          _thumbnailBytes = bytes;
          //debugPrint("Thumbnail generated! Size: ${_thumbnailBytes!.length}");
          widget.onImageLoaded?.call(_thumbnailBytes);
        });
      }
    } catch (e) {
      debugPrint("Thumbnail generation failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailBytes != null) {
      return Image.memory(
        _thumbnailBytes!,
        fit: BoxFit.contain,
      );
    }

    // render once offscreen → generate thumbnail
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateThumbnail());

    return RepaintBoundary(
      key: _repaintKey,
      child: MasonryGridView.builder(
        shrinkWrap: true, // ✅ expands naturally with content
        physics:
            const NeverScrollableScrollPhysics(), // ✅ let parent handle scroll
        cacheExtent: 10,
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.imageUrls.length > 4 ? 3 : 2,
        ),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          return Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: AspectRatio(
              aspectRatio: 1 / 1, // 👈 always square tiles
              child: CachedNetworkImage(
                imageUrl: url.isEmpty ? '' : url.trim(),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) {
                  return const CustomColoredBanner(text: '');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
