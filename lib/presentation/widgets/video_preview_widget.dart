import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;
  final double? aspectRatio;

  const VideoPreviewWidget({
    super.key,
    required this.videoUrl,
    this.onTap,
    this.aspectRatio = 9 / 16,
  });

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget>
    with SingleTickerProviderStateMixin {
  //late VideoPlayerController _controller;
  late final CachedVideoPlayerPlus _player;
  bool isInitialized = false;
  bool autoPlayVideo = false;
  IconData iconData = Icons.play_arrow;
  @override
  void initState() {
    autoPlayVideo = context.read<SettingsBloc>().state.autoPlayVideos ?? false;
    super.initState();
    // _controller =
    //     VideoPlayerController.networkUrl(
    //         Uri.parse("https://www.pexels.com/download/video/6752408/"),
    //       )
    //       ..initialize()
    //           .then((_) {
    //             // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
    //             setState(() {
    //               _isInitialized = true;
    //             });
    //           })
    //           .catchError((error) {
    //             debugPrint("Video init error: $error");
    //           });

    _player = CachedVideoPlayerPlus.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: {
        'Cache-Control': 'max-age=80085', // Time-tested cache duration
      },
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
      //viewType: VideoViewType.platformView,
      invalidateCacheIfOlderThan: const Duration(minutes: 69), // Nice!
    );

    _player
        .initialize()
        .then((_) {
          setState(() {});
          if (autoPlayVideo) {
            _player.controller.play();
            setState(() {
              iconData = Icons.pause;
            });
          }
          //_player.controller.play();
          _player.controller.setLooping(true);
          _player.controller.setVolume(0.0);
          _player.controller.setPlaybackSpeed(1.5);
        })
        .catchError((error) {
          //debugPrint("Video init error: $error");
        });
  }

  @override
  void dispose() {
    // _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: _player.isInitialized
                ? AspectRatio(
                    aspectRatio: widget.aspectRatio ?? 9 / 16,
                    child: VideoPlayer(
                      _player.controller,
                    ), // Note: VideoPlayer from video_player package!
                  )
                : const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
          ),
          Positioned(
            top: 12,
            right: 8,
            child: CustomIconButtonRounded(
              backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.4),
              onPressed: () {
                _player.controller.value.isPlaying
                    ? _player.controller.pause()
                    : _player.controller.play();
                setState(() {
                  iconData = _player.controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow;
                });
              },
              iconData: iconData,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
