import 'dart:async';

import 'package:flutter/foundation.dart';

/// Decides which feed video is allowed to play.
///
/// Deliberately owns **no** `VideoPlayerController`: it only answers "which key
/// is active". Each card creates its controller when it becomes active and
/// disposes it when it stops being active, so exactly one decoder ever exists
/// (plan §6.6, R2). That also makes the arbitration unit-testable without a
/// video plugin.
class VideoPlaybackManager extends ChangeNotifier {
  VideoPlaybackManager({
    this.minVisibleFraction = 0.6,
    this.debounce = const Duration(milliseconds: 250),
  });

  /// How much of a card must be visible before it may play.
  final double minVisibleFraction;

  /// Scroll events arrive in bursts; only re-decide after the burst settles.
  final Duration debounce;

  final Map<Object, double> _fractions = {};

  Object? _activeKey;
  Timer? _debounceTimer;
  bool _enabled = true;
  bool _muted = true;
  bool _appActive = true;
  bool _userPaused = false;
  bool _disposed = false;

  /// The card that may play right now.
  Object? get activeKey => _activeKey;

  /// `false` when the user turned autoplay off; cards then need a tap.
  bool get isEnabled => _enabled;

  bool get isMuted => _muted;

  bool get appIsActive => _appActive;

  /// Set by an explicit pause so the next scroll does not restart the clip.
  bool get isUserPaused => _userPaused;

  /// Autoplay preference from `SettingsBloc`.
  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (!enabled) {
      _activeKey = null;
      _userPaused = false;
    } else {
      _recompute();
    }
    _emit();
  }

  void setAppActive(bool active) {
    if (_appActive == active) return;
    _appActive = active;

    if (active) {
      // Coming back to the foreground restarts whichever card is still visible.
      _recompute(force: true);
    } else {
      // Leaving the foreground stops the decoder immediately.
      _activeKey = null;
    }
    _emit();
  }

  void toggleMuted() {
    _muted = !_muted;
    _emit();
  }

  void setMuted(bool muted) {
    if (_muted == muted) return;
    _muted = muted;
    _emit();
  }

  /// Called by a card while it scrolls in and out of view.
  void updateVisibility(Object key, double fraction) {
    final clamped = fraction.clamp(0.0, 1.0).toDouble();

    if (clamped <= 0) {
      _fractions.remove(key);
    } else {
      _fractions[key] = clamped;
    }

    _scheduleRecompute();
  }

  /// Called when a card is disposed so it cannot stay the active candidate.
  void remove(Object key) {
    final wasActive = _activeKey == key;
    _fractions.remove(key);
    if (wasActive) {
      _activeKey = null;
      _emit();
    }
  }

  /// Gives playback back after a screen-level player (the post detail hero)
  /// closes, so the card behind it resumes instead of staying stopped.
  ///
  /// Unlike [remove] this re-decides immediately: nothing scrolls when a route
  /// is popped, so no visibility event would arrive to restart the feed.
  void releaseFocus(Object key) {
    if (_activeKey != key) return;

    _fractions.remove(key);
    _activeKey = null;
    _userPaused = false;
    _recompute(force: true);
    _emit();
  }

  /// Play/pause from the card's own control.
  void togglePlayPause() {
    if (!_enabled && _activeKey == null) return;

    _userPaused = !_userPaused;
    if (!_userPaused) {
      // Explicit play also re-arms autoplay for the card under the finger.
      _recompute(force: true);
    }
    _emit();
  }

  /// A tap on a poster while autoplay is off.
  void playManually(Object key) {
    _userPaused = false;
    _activeKey = key;
    _emit();
  }

  void pause() {
    if (_activeKey == null && !_userPaused) return;
    _activeKey = null;
    _userPaused = true;
    _emit();
  }

  void _scheduleRecompute() {
    if (!_enabled) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => _recompute());
  }

  void _recompute({bool force = false}) {
    if (_disposed || !_enabled || !_appActive) return;

    // A user pause wins until the card leaves the viewport entirely.
    if (_userPaused && !force) return;

    Object? best;
    var bestFraction = 0.0;

    for (final entry in _fractions.entries) {
      if (entry.value > bestFraction) {
        best = entry.key;
        bestFraction = entry.value;
      }
    }

    final next = bestFraction >= minVisibleFraction ? best : null;
    if (next == _activeKey) return;

    _activeKey = next;
    _userPaused = false;
    _emit();
  }

  void _emit() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
