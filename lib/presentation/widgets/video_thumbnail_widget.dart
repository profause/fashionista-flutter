import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.onTap,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: widget.videoUrl,
      imageFormat: ImageFormat.PNG,
      maxWidth: 250, // reduce size → lightweight
      quality: 75,
    );

    if (mounted) {
      setState(() {
        _thumbnail = uint8list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _thumbnail != null
                ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                : Container(color: Colors.grey[300]),
          ),
          Container(
            color: Colors.black26,
            child: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 64,
            ),
          ),
        ],
      ),
    );
  }
}
