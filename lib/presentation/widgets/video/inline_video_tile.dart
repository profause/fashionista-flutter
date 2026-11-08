import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:fashionista/core/media/video_quality_analytics.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:fashionista/presentation/widgets/video/video_quality_selector.dart';
import 'package:fashionista/presentation/widgets/video/video_rendition_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Feed card for a video post.
///
/// The poster renders immediately; the decoder is created only while this card
/// is the manager's active key, and disposed as soon as it is not.
///
/// Playback always starts in [VideoQuality.sd]. The HD URL is only requested
/// when the user taps the quality pill, and the choice does not survive the card
/// being stopped (plan §5, §8).
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

  /// Delivery quality in use. Every card starts in SD.
  VideoQuality _quality = VideoQuality.sd;

  /// True while an HD controller is being prepared; the pill shows a spinner.
  bool _switchingQuality = false;

  /// Bumped whenever playback is torn down or a switch starts, so a late
  /// `initialize()` cannot activate a controller nobody wants any more.
  int _generation = 0;

  /// Public id of the video, resolved once: it never changes for a card.
  late final String? _publicId = CloudinaryVideoUrls.publicIdOf(widget.media);

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

  /// URL of [quality]; falls back to the stored original when the public id is
  /// unknown, so odd documents still play.
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

    final url = _urlFor(_quality);
    if (url == null) return;

    final generation = _generation;
    final startedAt = DateTime.now();
    _initializing = true;

    try {
      final controller = await _openInitial(url, muted: manager.isMuted);
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
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

  /// One retry, then the stored original.
  ///
  /// A freshly uploaded video may still be transcoding (Cloudinary answers 423
  /// until the rendition exists), and playback must never be blocked by that.
  Future<VideoPlayerController> _openInitial(
    Uri url, {
    required bool muted,
  }) async {
    try {
      return await loadVideoRendition(url: url, muted: muted);
    } catch (_) {
      if (!mounted) rethrow;

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      try {
        return await loadVideoRendition(url: url, muted: muted);
      } catch (_) {
        final original = widget.media.url;
        if (original == null ||
            original.isEmpty ||
            original == url.toString()) {
          rethrow;
        }
        return loadVideoRendition(url: Uri.parse(original), muted: muted);
      }
    }
  }

  /// Swaps the running controller to [target] without losing the position,
  /// the play state or the mute state.
  Future<void> _switchQuality(VideoQuality target) async {
    if (target == _quality || _switchingQuality) return;

    final current = _controller;
    final url = _urlFor(target);
    if (current == null || url == null) {
      // Nothing is playing: change what the next start will use. While a start
      // is in flight the controller is about to appear as SD, so ignore it.
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
      _showQualityError(target);
      return;
    }

    // Scrolled away or another switch started while HD was initializing.
    if (!mounted || generation != _generation) {
      await next.dispose();
      return;
    }

    setState(() {
      _controller = next;
      _quality = target;
      _switchingQuality = false;
    });

    // The new controller is already painted, so pausing the old one here is not
    // a black frame: it only stops the two decoders overlapping in sound.
    await current.pause();
    if (wasPlaying) await next.play();
    await current.dispose();

    VideoQualityAnalytics.instance.log(
      VideoQualityEvent.hdPlaybackStarted,
      quality: target,
      durationMs: DateTime.now().difference(startedAt).inMilliseconds,
    );
  }

  void _showQualityError(VideoQuality target) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '${target.label} could not be loaded. '
          'Still playing ${_quality.label}.',
        ),
        duration: const Duration(seconds: 3),
      ),
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
    setState(() => _controller = null);
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
            // Only while this card is opening a decoder: an idle card is just
            // its poster, and a spinner there reads as "stuck".
            if (_initializing && _controller == null)
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
              quality: _quality,
              switchingQuality: _switchingQuality,
              canSwitchQuality: _canSwitchQuality,
              onQualitySelected: _switchQuality,
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
  final VideoQuality quality;
  final bool switchingQuality;
  final bool canSwitchQuality;
  final VoidCallback onPlayPause;
  final VoidCallback onMuteToggle;
  final ValueChanged<VideoQuality> onQualitySelected;

  const _Controls({
    required this.media,
    required this.isPlaying,
    required this.isMuted,
    required this.quality,
    required this.switchingQuality,
    required this.canSwitchQuality,
    required this.onPlayPause,
    required this.onMuteToggle,
    required this.onQualitySelected,
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
        // Next to play/pause: thumb-reachable, clear of the mute control.
        Positioned(
          bottom: 8,
          left: 44,
          child: VideoQualitySelector(
            quality: quality,
            switching: switchingQuality,
            isAvailable: canSwitchQuality,
            onSelect: onQualitySelected,
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
