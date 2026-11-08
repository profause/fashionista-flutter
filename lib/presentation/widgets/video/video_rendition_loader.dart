import 'package:video_player/video_player.dart';

/// Opens a rendition and restores the playback state a switch has to preserve.
///
/// The caller owns the returned controller and must dispose it. On failure the
/// half-open controller is disposed here, so a failed attempt never leaks a
/// decoder.
Future<VideoPlayerController> loadVideoRendition({
  required Uri url,
  Duration position = Duration.zero,
  bool muted = true,
  bool playing = true,
}) async {
  final controller = VideoPlayerController.networkUrl(url);

  try {
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(muted ? 0 : 1);

    if (position > Duration.zero) {
      await controller.seekTo(position);
    }
    if (playing) {
      await controller.play();
    }

    return controller;
  } catch (_) {
    await controller.dispose();
    rethrow;
  }
}
