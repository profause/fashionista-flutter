import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration settle = Duration(milliseconds: 300);

/// Waits out the manager's debounce.
Future<void> afterDebounce() => Future<void>.delayed(settle);

void main() {
  late VideoPlaybackManager manager;

  setUp(() => manager = VideoPlaybackManager());
  tearDown(() => manager.dispose());

  test('a barely visible card does not autoplay', () async {
    manager.updateVisibility('a', 0.3);
    await afterDebounce();

    expect(manager.activeKey, isNull);
  });

  test('the most visible card becomes the active one', () async {
    manager.updateVisibility('a', 0.7);
    manager.updateVisibility('b', 0.9);
    await afterDebounce();

    expect(manager.activeKey, 'b');
  });

  test('only one key can be active', () async {
    manager.updateVisibility('a', 0.8);
    manager.updateVisibility('b', 0.85);
    await afterDebounce();

    expect(manager.activeKey, 'b');

    manager.updateVisibility('a', 0.95);
    await afterDebounce();

    expect(manager.activeKey, 'a');
  });

  test('scrolling away clears the active key', () async {
    manager.updateVisibility('a', 0.9);
    await afterDebounce();
    expect(manager.activeKey, 'a');

    manager.updateVisibility('a', 0);
    await afterDebounce();

    expect(manager.activeKey, isNull);
  });

  test('an explicit pause survives the next scroll', () async {
    manager.updateVisibility('a', 0.9);
    await afterDebounce();

    manager.togglePlayPause(); // user pauses
    expect(manager.isUserPaused, isTrue);

    manager.updateVisibility('a', 0.95);
    await afterDebounce();

    expect(manager.activeKey, 'a');
    expect(manager.isUserPaused, isTrue);
  });

  test(
    'a user pause stops playback even while the card stays visible',
    () async {
      manager.updateVisibility('a', 0.9);
      await afterDebounce();

      manager.pause();

      expect(manager.activeKey, isNull);
      expect(manager.isUserPaused, isTrue);
    },
  );

  test('disabling autoplay clears the active key', () async {
    manager.updateVisibility('a', 0.9);
    await afterDebounce();

    manager.setEnabled(false);

    expect(manager.activeKey, isNull);
    expect(manager.isEnabled, isFalse);
  });

  test('a manual play works while autoplay is off', () {
    manager.setEnabled(false);

    manager.playManually('a');

    expect(manager.activeKey, 'a');
  });

  test(
    'backgrounding the app stops playback and resuming re-arms it',
    () async {
      manager.updateVisibility('a', 0.9);
      await afterDebounce();

      manager.setAppActive(false);
      expect(manager.activeKey, isNull);

      manager.setAppActive(true);
      await afterDebounce();

      expect(manager.activeKey, 'a');
    },
  );

  test('a disposed card cannot stay active', () async {
    manager.updateVisibility('a', 0.9);
    await afterDebounce();

    manager.remove('a');

    expect(manager.activeKey, isNull);
  });

  test('mute state is shared by every card', () {
    expect(manager.isMuted, isTrue);

    manager.toggleMuted();
    expect(manager.isMuted, isFalse);

    manager.setMuted(true);
    expect(manager.isMuted, isTrue);
  });

  test('a detail-screen player can take playback from the feed', () async {
    manager.updateVisibility('feed', 0.9);
    await afterDebounce();
    expect(manager.activeKey, 'feed');

    manager.playManually('detail');
    expect(manager.activeKey, 'detail');
  });

  test('releasing the focus gives playback back to the visible card', () async {
    manager.updateVisibility('feed', 0.9);
    await afterDebounce();

    manager.playManually('detail');
    manager.releaseFocus('detail');

    // Nothing scrolls when a route pops, so this must not wait for a visibility
    // event.
    expect(manager.activeKey, 'feed');
  });

  test('releasing a focus it does not own changes nothing', () async {
    manager.updateVisibility('feed', 0.9);
    await afterDebounce();

    manager.releaseFocus('detail');

    expect(manager.activeKey, 'feed');
  });

  test('notifies listeners when the active key changes', () async {
    var notifications = 0;
    manager.addListener(() => notifications++);

    manager.updateVisibility('a', 0.9);
    await afterDebounce();

    expect(notifications, greaterThan(0));
  });
}
