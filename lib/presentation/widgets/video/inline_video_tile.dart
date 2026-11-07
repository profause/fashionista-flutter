import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Feed card for a video post.
///
/// The poster renders immediately; the decoder is created only while this card
/// is the manager's active key, and disposed as soon as it is not.
class InlineVideoTile extends StatefulWidget {
  final FeaturedMediaModel media;
  final Object playbackKey;

  const InlineVideoTile({
    super.key,
    required this.media,
    required this.playbackKey,
  });

  @override
  State<InlineVideoTile> createState() => _InlineVideoTileState();
}

class _InlineVideoTileState extends State<InlineVideoTile> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _failed = false;
  bool _firstFrameReady = false;

  /// Set when autoplay is off and the user tapped this poster.
  bool _manualPlay = false;

  VideoPlaybackManager? _listeningTo;

  VideoPlaybackManager get _manager => context.read<VideoPlaybackManager>();

  bool _shouldPlay(VideoPlaybackManager manager) {
    if (!manager.appIsActive) return false;
    if (manager.isUserPaused) return false;
    if (!manager.isEnabled) return _manualPlay;

    return manager.activeKey == widget.playbackKey;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final manager = context.read<VideoPlaybackManager>();
    if (!identical(_listeningTo, manager)) {
      _listeningTo?.removeListener(_onManagerChanged);
      _listeningTo = manager..addListener(_onManagerChanged);
    }

    _sync();
  }

  /// Another card became active, the user paused, or the app was backgrounded.
  void _onManagerChanged() {
    if (mounted) _sync();
  }

  void _sync() {
    final manager = context.read<VideoPlaybackManager>();
    if (_shouldPlay(manager)) {
      _start(manager);
    } else {
      _stop();
    }
  }

  Future<void> _start(VideoPlaybackManager manager) async {
    if (_controller != null || _initializing || _failed) {
      final controller = _controller;
      if (controller != null) {
        await controller.setVolume(manager.isMuted ? 0 : 1);
        if (manager.isUserPaused) {
          await controller.pause();
        } else {
          await controller.play();
        }
      }
      return;
    }

    final url = widget.media.url;
    if (url == null || url.isEmpty) return;

    _initializing = true;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(manager.isMuted ? 0 : 1);
      await controller.play();

      setState(() {
        _controller = controller;
        _initializing = false;
        _firstFrameReady = true;
      });
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _failed = true;
      });
    }
  }

  Future<void> _stop() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.pause();
    await controller.dispose();
    if (!mounted) return;
    setState(() {
      _controller = null;
      _firstFrameReady = false;
    });
  }

  @override
  void dispose() {
    final manager = _listeningTo;
    manager?.removeListener(_onManagerChanged);
    manager?.remove(widget.playbackKey);
    _listeningTo = null;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = widget.media.aspectRatio ?? 9 / 16;

    return VisibilityDetector(
      key: ValueKey('visibility_${widget.playbackKey}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        context.read<VideoPlaybackManager>().updateVisibility(
          widget.playbackKey,
          info.visibleFraction,
        );
        _sync();
      },
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Poster(media: widget.media),
            if (_controller != null) VideoPlayer(_controller!),
            if (!_firstFrameReady)
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),
            if (_failed) const _PlaybackFailedOverlay(),
            _Controls(
              media: widget.media,
              isPlaying: _controller?.value.isPlaying ?? false,
              isMuted: _manager.isMuted,
              onPlayPause: () {
                final manager = _manager;
                if (!manager.isEnabled) {
                  setState(() => _manualPlay = !_manualPlay);
                  _sync();
                  return;
                }
                manager.togglePlayPause();
                _sync();
              },
              onMuteToggle: () {
                _manager.toggleMuted();
                _sync();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final FeaturedMediaModel media;

  const _Poster({required this.media});

  @override
  Widget build(BuildContext context) {
    final url = media.thumbnailUrl;

    if (url == null || url.isEmpty) {
      return Container(color: context.cardSurface);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) =>
          Container(color: context.cardSurface),
    );
  }
}

class _PlaybackFailedOverlay extends StatelessWidget {
  const _PlaybackFailedOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(Icons.error_outline, color: Colors.white70),
    );
  }
}

class _Controls extends StatelessWidget {
  final FeaturedMediaModel media;
  final bool isPlaying;
  final bool isMuted;
  final VoidCallback onPlayPause;
  final VoidCallback onMuteToggle;

  const _Controls({
    required this.media,
    required this.isPlaying,
    required this.isMuted,
    required this.onPlayPause,
    required this.onMuteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 8,
          left: 8,
          child: _RoundButton(
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            onTap: onPlayPause,
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: _RoundButton(
            icon: isMuted ? Icons.volume_off : Icons.volume_up,
            onTap: onMuteToggle,
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
