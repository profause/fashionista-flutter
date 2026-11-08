import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/video/trend_video_hero.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const FeaturedMediaModel videoMedia = FeaturedMediaModel(
  uid: 'fashionista/trends/videos/u1/trend_1',
  type: 'video',
  url: 'https://example.invalid/video.mp4',
  thumbnailUrl: 'https://example.invalid/poster.jpg',
  aspectRatio: 9 / 16,
  duration: 12,
  width: 720,
  height: 1280,
  hasAudio: true,
);

const FeaturedMediaModel silentMedia = FeaturedMediaModel(
  uid: 'fashionista/trends/videos/u1/trend_2',
  type: 'video',
  url: 'https://example.invalid/silent.mp4',
  thumbnailUrl: 'https://example.invalid/poster.jpg',
  aspectRatio: 9 / 16,
  hasAudio: false,
);

Future<void> pumpHero(
  WidgetTester tester,
  VideoPlaybackManager manager, {
  FeaturedMediaModel media = videoMedia,
  Object key = 'detail',
  String caption = 'A caption',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: fashionistaLightTheme,
      home: ChangeNotifierProvider<VideoPlaybackManager>.value(
        value: manager,
        child: Scaffold(
          // A 9:16 hero at full test width would be taller than the 800x600
          // surface, putting the controls off-screen.
          body: Center(
            child: SizedBox(
              width: 300,
              child: TrendVideoHero(
                media: media,
                caption: caption,
                playbackKey: key,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // The claim runs post-frame; the decoder then fails (no plugin in tests).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('renders the poster, the caption and the controls', (
    tester,
  ) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpHero(tester, manager);

    expect(find.byType(TrendVideoHero), findsOneWidget);
    expect(find.text('A caption'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
  });

  testWidgets('a silent clip hides the mute control', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpHero(tester, manager, media: silentMedia);

    expect(find.byIcon(Icons.volume_off), findsNothing);
    expect(find.byIcon(Icons.volume_up), findsNothing);
  });

  testWidgets('with autoplay off it does not steal playback from the feed', (
    tester,
  ) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpHero(tester, manager);

    expect(manager.activeKey, isNull);
  });

  testWidgets('with autoplay on it takes playback from the feed', (
    tester,
  ) async {
    final manager = VideoPlaybackManager();
    addTearDown(manager.dispose);

    await pumpHero(tester, manager, key: 'detail');

    expect(manager.activeKey, 'detail');
  });

  testWidgets('tapping play claims playback when autoplay is off', (
    tester,
  ) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpHero(tester, manager, key: 'detail');
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(milliseconds: 50));

    expect(manager.activeKey, 'detail');
  });

  testWidgets('the mute button flips the shared mute state', (tester) async {
    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await pumpHero(tester, manager);
    expect(manager.isMuted, isTrue);

    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump();

    expect(manager.isMuted, isFalse);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
  });

  testWidgets('unmounting while active does not notify during the locked '
      'build', (tester) async {
    final manager = VideoPlaybackManager();
    addTearDown(manager.dispose);

    manager.updateVisibility('feed', 0.9);
    await tester.pump(const Duration(milliseconds: 300));

    // The provider stays mounted while the hero goes away, which is what a
    // route pop looks like: notifying from dispose() then marks the provider
    // dirty while the tree is locked.
    var showHero = true;

    await tester.pumpWidget(
      MaterialApp(
        theme: fashionistaLightTheme,
        home: ChangeNotifierProvider<VideoPlaybackManager>.value(
          value: manager,
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => showHero
                  ? Column(
                      children: [
                        TextButton(
                          onPressed: () => setState(() => showHero = false),
                          child: const Text('remove'),
                        ),
                        SizedBox(
                          width: 300,
                          child: TrendVideoHero(
                            media: videoMedia,
                            caption: '',
                            playbackKey: 'detail',
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(manager.activeKey, 'detail');

    await tester.tap(find.text('remove'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(manager.activeKey, 'feed');
  });

  testWidgets('closing the screen hands playback back to the feed', (
    tester,
  ) async {
    final manager = VideoPlaybackManager();
    addTearDown(manager.dispose);

    manager.updateVisibility('feed', 0.9);
    await tester.pump(const Duration(milliseconds: 300));

    await pumpHero(tester, manager, key: 'detail');
    expect(manager.activeKey, 'detail');

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );

    expect(manager.activeKey, 'feed');
  });
}
