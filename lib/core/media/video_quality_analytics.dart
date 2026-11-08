import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:flutter/foundation.dart';

/// What happened to a video's quality, for bandwidth and adoption reporting.
enum VideoQualityEvent {
  /// A card started playing its default (SD) rendition.
  sdPlaybackStarted,

  /// The user asked for HD on the card being watched.
  hdRequested,

  /// HD finished initializing and took over from SD.
  hdPlaybackStarted,

  /// HD could not be initialized; SD kept playing.
  hdSwitchFailed,

  /// A rendition took longer than expected before its first frame.
  startupDelay,
}

/// Analytics seam for video delivery.
///
/// The app has no analytics SDK yet, so the default implementation only logs in
/// debug. Deliberately never receives URLs or public ids: they identify media,
/// and the upload URLs carry no user data but the public id still does.
abstract class VideoQualityAnalytics {
  void log(
    VideoQualityEvent event, {
    VideoQuality? quality,
    int? durationMs,
    String? reason,
  });

  /// Swappable so tests can record events and a real SDK can be dropped in
  /// later without touching the widgets.
  static VideoQualityAnalytics instance = const DebugVideoQualityAnalytics();
}

/// Debug-only sink: no network, no identifiers.
class DebugVideoQualityAnalytics implements VideoQualityAnalytics {
  const DebugVideoQualityAnalytics();

  @override
  void log(
    VideoQualityEvent event, {
    VideoQuality? quality,
    int? durationMs,
    String? reason,
  }) {
    if (!kDebugMode) return;

    final parts = <String>[
      event.name,
      ?quality?.label,
      if (durationMs != null) '${durationMs}ms',
      ?reason,
    ];
    debugPrint('[video-quality] ${parts.join(' ')}');
  }
}
