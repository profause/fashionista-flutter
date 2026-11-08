import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:fashionista/core/media/video_quality_analytics.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/featured_media_caption.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:fashionista/presentation/widgets/video/video_quality_selector.dart';
import 'package:fashionista/presentation/widgets/video/video_rendition_loader.dart';
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

  /// Delivery quality in use; the hero also starts in SD.
  VideoQuality _quality = VideoQuality.sd;
  bool _switchingQuality = false;

  /// Invalidates an in-flight `initialize()` when playback is torn down or the
  /// user asks for another quality.
  int _generation = 0;

  late final String? _publicId = CloudinaryVideoUrls.publicIdOf(widget.media);

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

  /// URL of [quality], falling back to the stored original when the public id
  /// is unknown.
  Uri? _urlFor(VideoQuality quality) {
    final publicId = _publicId;
    if (publicId != null) {
      return CloudinaryVideoUrls.rendition(publicId, quality);
    }

    final raw = widget.media.url;
    if (raw == null || raw.isEmpty) return null;
    return Uri.tryParse(raw);
  }

  bool get _canSwitchQuality => _publicId != null;

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

    final url = _urlFor(_quality);
    if (url == null) return;

    final generation = _generation;
    final startedAt = DateTime.now();
    _initializing = true;

    try {
      final controller = await loadVideoRendition(
        url: url,
        muted: manager.isMuted,
      );
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
        _firstFrameReady = true;
      });

      VideoQualityAnalytics.instance.log(
        VideoQualityEvent.sdPlaybackStarted,
        quality: _quality,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _initializing = false;
        _failed = true;
      });
    }
  }

  /// Swaps the running controller to [target], keeping position, mute and play
  /// state. On failure SD keeps playing and the user is told.
  Future<void> _switchQuality(VideoQuality target) async {
    if (target == _quality || _switchingQuality) return;

    final current = _controller;
    final url = _urlFor(target);
    if (current == null || url == null) {
      // Nothing is playing yet; a start already in flight will come up as SD.
      if (_initializing || url == null) return;
      setState(() => _quality = target);
      return;
    }

    final generation = ++_generation;
    final position = current.value.position;
    final wasPlaying = current.value.isPlaying;
    final muted = _manager.isMuted;
    final startedAt = DateTime.now();

    setState(() => _switchingQuality = true);
    VideoQualityAnalytics.instance.log(
      VideoQualityEvent.hdRequested,
      quality: target,
    );

    VideoPlayerController next;
    try {
      next = await loadVideoRendition(
        url: url,
        position: position,
        muted: muted,
        playing: false,
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;

      setState(() => _switchingQuality = false);
      VideoQualityAnalytics.instance.log(
        VideoQualityEvent.hdSwitchFailed,
        quality: target,
        reason: '$error',
      );
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            '${target.label} could not be loaded. '
            'Still playing ${_quality.label}.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted || generation != _generation) {
      await next.dispose();
      return;
    }

    setState(() {
      _controller = next;
      _quality = target;
      _switchingQuality = false;
    });

    await current.pause();
    if (wasPlaying) await next.play();
    await current.dispose();

    VideoQualityAnalytics.instance.log(
      VideoQualityEvent.hdPlaybackStarted,
      quality: target,
      durationMs: DateTime.now().difference(startedAt).inMilliseconds,
    );
  }

  Future<void> _stop() async {
    final controller = _controller;
    final wasSwitching = _switchingQuality;

    _generation++;
    _quality = VideoQuality.sd;
    _switchingQuality = false;

    if (controller == null) {
      if (wasSwitching && mounted) setState(() {});
      return;
    }

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

            if (_canSwitchQuality)
              Positioned(
                top: 8,
                left: 8,
                child: VideoQualitySelector(
                  quality: _quality,
                  switching: _switchingQuality,
                  onSelect: _switchQuality,
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
