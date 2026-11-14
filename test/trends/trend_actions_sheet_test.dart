import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final trend = TrendFeedModel.empty().copyWith(
    uid: 'trend_1',
    description: 'A test trend',
    createdBy: 'author_1',
  );

  Future<void> openSheet(
    WidgetTester tester, {
    required bool canReport,
    required ValueNotifier<TrendAction?> result,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showTrendActionsSheet(
                  context,
                  trend: trend,
                  canReport: canReport,
                ).then((value) => result.value = value);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows download, share and report with icons', (tester) async {
    await openSheet(
      tester,
      canReport: true,
      result: ValueNotifier<TrendAction?>(null),
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('selecting report returns the report action', (tester) async {
    final result = ValueNotifier<TrendAction?>(null);
    await openSheet(tester, canReport: true, result: result);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(result.value, TrendAction.report);
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('hides report when the viewer cannot report', (tester) async {
    await openSheet(
      tester,
      canReport: false,
      result: ValueNotifier<TrendAction?>(null),
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Report'), findsNothing);
  });
}
