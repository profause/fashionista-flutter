import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/trend_audience.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_audience_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TrendAudience? result;
  late bool completed;

  setUp(() {
    result = null;
    completed = false;
  });

  Future<void> openSheet(
    WidgetTester tester, {
    TrendAudience current = TrendAudience.public,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: fashionistaLightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTrendAudienceSheet(
                  context,
                  current: current,
                );
                completed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists Public and Draft with the current one selected', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles, hasLength(2));
    // The current audience is the highlighted row.
    final selected = tiles.where((tile) => tile.selected == true).toList();
    expect(selected, hasLength(1));
    expect((selected.single.title as Text).data, TrendAudience.public.label);
  });

  testWidgets('picking Draft closes the sheet with the choice', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();

    expect(find.byType(TrendAudienceSheet), findsNothing);
    expect(completed, isTrue);
    expect(result, TrendAudience.draft);
  });

  testWidgets('the current audience can be re-applied', (tester) async {
    await openSheet(tester, current: TrendAudience.draft);

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();

    expect(result, TrendAudience.draft);
  });

  testWidgets('dismissing returns null so the composer keeps its choice', (
    tester,
  ) async {
    await openSheet(tester);

    // Tap the barrier above the sheet.
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();

    expect(find.byType(TrendAudienceSheet), findsNothing);
    expect(completed, isTrue);
    expect(result, isNull);
  });
}
