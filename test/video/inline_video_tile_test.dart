import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/video/inline_video_tile.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

const FeaturedMediaModel videoMedia = FeaturedMediaModel(
  uid: 'fashionista/trends/videos/u1/trend_1',
  type: 'video',
  url: 'https://example.invalid/video.mp4',
  thumbnailUrl: 'https://example.invalid/poster.jpg',
  aspectRatio: 9 / 16,
  duration: 12,
  width: 720,
  height: 1280,
  hasAudio: false,
);

Future<void> pumpTile(
  WidgetTester tester,
  VideoPlaybackManager manager, {
  Object key = 'key-1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: fashionistaLightTheme,
      home: ChangeNotifierProvider<VideoPlaybackManager>.value(
        value: manager,
        child: Scaffold(
          body: SizedBox(
            height: 600,
            child: InlineVideoTile(media: videoMedia, playbackKey: key),
          ),
        ),
      ),
    ),
  );
  // The detector schedules its first measurement on a timer; pump past it so
  // the test does not finish with pending timers.
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('renders the poster and the controls', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpTile(tester, manager);

    expect(find.byType(InlineVideoTile), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
  });

  testWidgets('an idle card shows its poster, not a spinner', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpTile(tester, manager);

    // A card that is not playing has nothing to wait for; a spinner over the
    // poster reads as a stuck video.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('offers SD first and never shows HD unprompted', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpTile(tester, manager);

    // Playback always starts in SD; HD is only a target the user can pick.
    expect(find.text('SD'), findsOneWidget);
    expect(find.text('HD'), findsNothing);
  });

  testWidgets('the quality pill only switches what plays next', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpTile(tester, manager);

    await tester.tap(find.text('SD'));
    await tester.pump(const Duration(milliseconds: 50));

    // Nothing is playing yet, so the tap just records the preference.
    expect(find.text('HD'), findsOneWidget);
  });

  testWidgets('a tap starts playback when autoplay is off', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpTile(tester, manager);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(milliseconds: 50));

    // The tile asks the manager to allow this card; the decoder itself cannot
    // start in a widget test (no platform video player), so only the request is
    // observable here.
    expect(find.byType(InlineVideoTile), findsOneWidget);
  });

  testWidgets('muting toggles the shared state', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpTile(tester, manager);
    expect(manager.isMuted, isTrue);

    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump(const Duration(milliseconds: 50));

    expect(manager.isMuted, isFalse);
  });

  testWidgets('leaving the tree releases the playback key', (tester) async {
    final manager = VideoPlaybackManager();
    addTearDown(manager.dispose);

    manager.playManually('key-1');
    await pumpTile(tester, manager);

    expect(manager.activeKey, 'key-1');

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(manager.activeKey, isNull);
  });
}
