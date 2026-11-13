import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

const FeaturedMediaModel videoMedia = FeaturedMediaModel(
  uid: 'fashionista/trends/videos/u1/trend_1',
  type: 'video',
  url: 'https://example.invalid/video.mp4',
  thumbnailUrl: 'https://example.invalid/poster.jpg',
  aspectRatio: 3 / 4,
  duration: 12,
  width: 720,
  height: 1280,
  hasAudio: false,
);

const String caption =
    'A long enough caption to paint the gradient banner over the bottom of '
    'the media, right where the playback and mute controls sit.';

final TrendFeedModel videoTrend = TrendFeedModel(
  uid: 'trend_1',
  description: caption,
  featuredMedia: const [videoMedia],
  createdAt: 0,
  updatedAt: 0,
  createdBy: 'author_1',
  tags: '',
  author: const AuthorModel(
    uid: 'author_1',
    name: 'Author One',
    avatar: 'https://example.invalid/avatar.jpg',
  ),
);

Future<VideoPlaybackManager> pumpCard(WidgetTester tester) async {
  final manager = VideoPlaybackManager()..setEnabled(false);
  addTearDown(manager.dispose);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: TrendInfoCardWidget(
                trendInfo: videoTrend,
                aspectRatio: 3 / 4,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/trends/:id',
        builder: (context, state) =>
            const Scaffold(body: Text('trend details')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<VideoPlaybackManager>.value(
      value: manager,
      child: MaterialApp.router(
        theme: fashionistaLightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));

  return manager;
}

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('the mute control wins over the card navigation tap', (
    tester,
  ) async {
    final manager = await pumpCard(tester);
    expect(manager.isMuted, isTrue);

    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump(const Duration(milliseconds: 50));

    expect(manager.isMuted, isFalse);
    expect(find.text('trend details'), findsNothing);
  });

  testWidgets('the playback control wins over the card navigation tap', (
    tester,
  ) async {
    await pumpCard(tester);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('trend details'), findsNothing);
  });

  testWidgets('tapping the caption still opens the trend', (tester) async {
    await pumpCard(tester);

    await tester.tapAt(tester.getCenter(find.text(caption)));
    await tester.pumpAndSettle();

    expect(find.text('trend details'), findsOneWidget);
  });
}
