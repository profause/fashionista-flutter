import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/discover_more_section.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'trend_feed_fakes.dart';

const FeaturedMediaModel portraitVideo = FeaturedMediaModel(
  uid: 'fashionista/trends/videos/related',
  type: 'video',
  url: 'https://example.invalid/video.mp4',
  thumbnailUrl: 'https://example.invalid/poster.jpg',
  aspectRatio: 9 / 16,
  duration: 12,
  width: 720,
  height: 1280,
  hasAudio: false,
);

void main() {
  late FakeTrendsService service;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    service = FakeTrendsService();
    sl.registerSingleton<FirebaseTrendsService>(service);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget sectionApp({
    required List<String> tags,
    String? excludeTrendId,
    required VideoPlaybackManager manager,
  }) {
    return MaterialApp(
      theme: fashionistaLightTheme,
      home: ChangeNotifierProvider<VideoPlaybackManager>.value(
        value: manager,
        child: Scaffold(
          body: SingleChildScrollView(
            child: DiscoverMoreSection(
              tags: tags,
              excludeTrendId: excludeTrendId,
            ),
          ),
        ),
      ),
    );
  }

  Future<VideoPlaybackManager> pumpSection(
    WidgetTester tester, {
    required List<String> tags,
    String? excludeTrendId,
  }) async {
    tester.view.physicalSize = const Size(1080, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final manager = VideoPlaybackManager()..setEnabled(false);
    addTearDown(manager.dispose);

    await tester.pumpWidget(
      sectionApp(tags: tags, excludeTrendId: excludeTrendId, manager: manager),
    );
    await tester.pump();
    // Drain the visibility detector's first measurement timer.
    await tester.pump(const Duration(milliseconds: 600));

    return manager;
  }

  testWidgets('shows related trends and hides the current post', (
    tester,
  ) async {
    service.tagQueue.add(
      Right<String, List<TrendFeedModel>>([
        trend('current'),
        trend('related-1'),
        trend('related-2'),
      ]),
    );

    await pumpSection(
      tester,
      tags: const ['summer', 'linen'],
      excludeTrendId: 'current',
    );

    expect(service.tagRequests, hasLength(1));
    expect(service.tagRequests.single.tags, ['summer', 'linen']);
    expect(find.text('Discover more'), findsOneWidget);
    expect(find.byType(TrendInfoCardWidget), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('discover-more-related-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('discover-more-current')), findsNothing);
  });

  testWidgets('normalises, trims and dedupes tags', (tester) async {
    service.tagQueue.add(
      Right<String, List<TrendFeedModel>>([trend('related')]),
    );

    await pumpSection(tester, tags: const [' Summer ', 'LINEN', 'summer', '']);

    expect(service.tagRequests.single.tags, ['summer', 'linen']);
  });

  testWidgets('renders nothing without tags', (tester) async {
    await pumpSection(tester, tags: const []);

    expect(service.tagRequests, isEmpty);
    expect(find.text('Discover more'), findsNothing);
  });

  testWidgets('renders nothing when there are no matches', (tester) async {
    service.tagQueue.add(
      const Right<String, List<TrendFeedModel>>(<TrendFeedModel>[]),
    );

    await pumpSection(tester, tags: const ['summer']);

    expect(find.text('Discover more'), findsNothing);
  });

  testWidgets('renders nothing when the fetch fails', (tester) async {
    service.tagQueue.add(const Left<String, List<TrendFeedModel>>('boom'));

    await pumpSection(tester, tags: const ['summer']);

    expect(find.text('Discover more'), findsNothing);
  });

  testWidgets('does not refetch when rebuilt with the same tags', (
    tester,
  ) async {
    service.tagQueue.add(
      Right<String, List<TrendFeedModel>>([trend('related')]),
    );

    final manager = await pumpSection(tester, tags: const ['summer']);
    expect(service.tagRequests, hasLength(1));

    await tester.pumpWidget(
      sectionApp(tags: const ['summer'], manager: manager),
    );
    await tester.pump();

    expect(service.tagRequests, hasLength(1));
  });

  testWidgets('clamps portrait media to the rail slot', (tester) async {
    service.tagQueue.add(
      Right<String, List<TrendFeedModel>>([
        trend('related').copyWith(featuredMedia: const [portraitVideo]),
      ]),
    );

    await pumpSection(tester, tags: const ['summer']);

    // A 9:16 card at the 150px rail width is ~267px tall; the slot is 200px.
    // Letting the media drive the card height overflows the rail, which fails
    // this test through the framework's RenderFlex assertion.
    expect(find.byType(TrendInfoCardWidget), findsOneWidget);
    expect(find.text('Discover more'), findsOneWidget);
  });
}
