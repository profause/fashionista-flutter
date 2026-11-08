import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/featured_media_caption.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

/// Hero player for a video post on the detail screen.
///
/// The feed arbitrates through [VideoPlaybackManager] so only one decoder ever
/// exists; this screen takes that ownership while it is on top (`playManually`)
/// and hands it back on dispose (`releaseFocus`), otherwise a feed card behind
/// the route would keep decoding and leaking audio.
class TrendVideoHero extends StatefulWidget {
  final FeaturedMediaModel media;
  final String caption;

  /// Must differ from the feed card's key: it identifies this player.
  final Object playbackKey;

  const TrendVideoHero({
    super.key,
    required this.media,
    required this.caption,
    required this.playbackKey,
  });

  /// Vertical clips are shown tall but never taller than this, so the rest of
  /// the post stays reachable without scrolling a full screen first.
  static const double minAspectRatio = 9 / 16;
  static const double maxAspectRatio = 16 / 9;

  @override
  State<TrendVideoHero> createState() => _TrendVideoHeroState();
}

class _TrendVideoHeroState extends State<TrendVideoHero> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _failed = false;
  bool _firstFrameReady = false;
  bool _claimed = false;

  /// Set by the hero's own play/pause control.
  bool _paused = false;

  VideoPlaybackManager? _listeningTo;

  VideoPlaybackManager get _manager => context.read<VideoPlaybackManager>();

  bool get _isOwner => _manager.activeKey == widget.playbackKey;

  bool get _canPlay =>
      _isOwner && _manager.appIsActive && !_manager.isUserPaused && !_paused;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final manager = context.read<VideoPlaybackManager>();
    if (!identical(_listeningTo, manager)) {
      _listeningTo?.removeListener(_onManagerChanged);
      _listeningTo = manager..addListener(_onManagerChanged);
    }

    if (!_claimed) {
      _claimed = true;
      // Notifying the manager during build would mark the feed cards dirty.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _claim(manager);
      });
    }

    _sync();
  }

  /// Takes playback away from whatever was playing behind this route.
  void _claim(VideoPlaybackManager manager) {
    if (!manager.appIsActive) return;

    if (manager.isEnabled) {
      manager.playManually(widget.playbackKey);
    } else if (manager.activeKey != null &&
        manager.activeKey != widget.playbackKey) {
      // Autoplay is off, but a manually started feed clip must still stop.
      manager.pause();
    }
  }

  void _onManagerChanged() {
    if (!mounted) return;

    // Nothing else may take playback while the hero is up and the user has not
    // paused it (a feed card could win a recompute after a resume).
    final manager = _manager;
    if (!_paused &&
        manager.isEnabled &&
        manager.appIsActive &&
        manager.activeKey != widget.playbackKey) {
      manager.playManually(widget.playbackKey);
      return;
    }

    _sync();
  }

  void _sync() {
    if (_canPlay) {
      _start();
    } else {
      _stop();
    }
  }

  Future<void> _start() async {
    final manager = _manager;
    final existing = _controller;

    if (existing != null) {
      await existing.setVolume(manager.isMuted ? 0 : 1);
      if (_canPlay && !existing.value.isPlaying) {
        await existing.play();
      }
      return;
    }

    if (_initializing || _failed) return;

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

  void _togglePlayPause() {
    final manager = _manager;

    if (!_isOwner) {
      setState(() => _paused = false);
      manager.playManually(widget.playbackKey);
      return;
    }

    setState(() => _paused = !_paused);
    if (_paused) {
      _controller?.pause();
    } else {
      manager.playManually(widget.playbackKey);
    }
  }

  void _toggleMuted() {
    _manager.toggleMuted();
    _sync();
  }

  @override
  void dispose() {
    _listeningTo?.removeListener(_onManagerChanged);
    // Hand the feed back before the controller goes away.
    _listeningTo?.releaseFocus(widget.playbackKey);
    _listeningTo = null;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _aspectRatio(widget.media);
    final isPlaying = _controller?.value.isPlaying ?? false;
    final hasAudio = widget.media.hasAudio != false;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
      ),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Poster(media: widget.media),

            if (_controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),

            if (!_firstFrameReady && !_failed)
              const Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),

            if (_failed) const _PlaybackFailed(),

            // Tap anywhere toggles, like every other video surface.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                child: const SizedBox.shrink(),
              ),
            ),

            if (!isPlaying && !_failed)
              Center(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _togglePlayPause,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

            if (hasAudio)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggleMuted,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      // The mute state is shared with the feed, so follow the
                      // manager instead of holding a local copy.
                      child: AnimatedBuilder(
                        animation: _manager,
                        builder: (context, _) => Icon(
                          _manager.isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (widget.caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FeaturedMediaCaption(text: widget.caption),
              ),

            if (_controller != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: VideoProgressColors(
                    playedColor: context.accent,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _aspectRatio(FeaturedMediaModel media) {
    final ratio = media.aspectRatio ?? 9 / 16;
    if (ratio.isNaN || ratio <= 0) return 9 / 16;
    return ratio.clamp(
      TrendVideoHero.minAspectRatio,
      TrendVideoHero.maxAspectRatio,
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
      return Container(color: Colors.black);
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Container(color: Colors.black),
    );
  }
}

class _PlaybackFailed extends StatelessWidget {
  const _PlaybackFailed();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.white70),
          SizedBox(height: 8),
          Text(
            'This video could not be played.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
