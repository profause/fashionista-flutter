import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/presentation/widgets/video/video_quality_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<VideoQuality>> pumpSelector(
  WidgetTester tester, {
  VideoQuality quality = VideoQuality.sd,
  bool switching = false,
  bool isAvailable = true,
}) async {
  final picks = <VideoQuality>[];

  await tester.pumpWidget(
    MaterialApp(
      theme: fashionistaLightTheme,
      home: Scaffold(
        body: Center(
          child: VideoQualitySelector(
            quality: quality,
            switching: switching,
            isAvailable: isAvailable,
            onSelect: picks.add,
          ),
        ),
      ),
    ),
  );

  return picks;
}

void main() {
  testWidgets('shows the quality in use, SD by default', (tester) async {
    await pumpSelector(tester);

    expect(find.text('SD'), findsOneWidget);
    expect(find.text('HD'), findsNothing);
  });

  testWidgets('tapping asks for the other quality', (tester) async {
    final picks = await pumpSelector(tester);

    await tester.tap(find.text('SD'));
    await tester.pump();

    expect(picks, [VideoQuality.hd]);
  });

  testWidgets('from HD the tap asks for SD', (tester) async {
    final picks = await pumpSelector(tester, quality: VideoQuality.hd);

    await tester.tap(find.text('HD'));
    await tester.pump();

    expect(picks, [VideoQuality.sd]);
  });

  testWidgets('while switching it spins and ignores taps', (tester) async {
    final picks = await pumpSelector(tester, switching: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('SD'), findsNothing);

    await tester.tap(find.byType(VideoQualitySelector));
    await tester.pump();

    expect(picks, isEmpty);
  });

  testWidgets('is hidden when no public id is known', (tester) async {
    await pumpSelector(tester, isAvailable: false);

    expect(find.byType(VideoQualitySelector), findsOneWidget);
    expect(find.text('SD'), findsNothing);
  });
}
