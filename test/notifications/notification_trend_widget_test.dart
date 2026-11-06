import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_trend_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

NotificationModel trendLike({
  String? refId = 'trend_1',
  String? status = 'new',
}) {
  return NotificationModel(
    uid: 'trend__liked__trend_1__liker_1',
    refId: refId,
    refType: 'trend',
    title: 'New like on your trend',
    description: 'Ama Boateng liked your trend.',
    type: 'trend',
    createdAt: DateTime.now()
        .subtract(const Duration(minutes: 5))
        .millisecondsSinceEpoch,
    status: status,
    to: 'author_1',
    event: 'trend_liked',
  );
}

NotificationModel trendComment({String? refId = 'trend_1'}) {
  return NotificationModel(
    uid: 'trend__commented__trend_1__comment_1',
    refId: refId,
    refType: 'trend',
    title: 'New comment on your trend',
    description: 'Ama Boateng commented: "This is stunning!"',
    type: 'trend',
    createdAt: DateTime.now()
        .subtract(const Duration(minutes: 2))
        .millisecondsSinceEpoch,
    status: 'new',
    to: 'author_1',
    event: 'trend_commented',
  );
}

Widget harness(Widget child, {List<String>? pushed}) {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/trends/:id',
        builder: (_, state) {
          pushed?.add('/trends/${state.pathParameters['id']}');
          return const Scaffold(body: Text('trend page'));
        },
      ),
    ],
  );

  return MaterialApp.router(
    theme: fashionistaLightTheme,
    routerConfig: router,
  );
}

void main() {
  group('NotificationTrendWidget', () {
    testWidgets('renders the title, body and view action', (tester) async {
      await tester.pumpWidget(
        harness(NotificationTrendWidget(notification: trendLike())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New like on your trend'), findsOneWidget);
      expect(find.text('Ama Boateng liked your trend.'), findsOneWidget);
      expect(find.text('View trend'), findsOneWidget);
    });

    testWidgets('opens the trend that was liked', (tester) async {
      final pushed = <String>[];
      var tapped = false;

      await tester.pumpWidget(
        harness(
          NotificationTrendWidget(
            notification: trendLike(),
            onTap: () => tapped = true,
          ),
          pushed: pushed,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('View trend'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue, reason: 'tapping must mark the row as read');
      expect(pushed, ['/trends/trend_1']);
      expect(find.text('trend page'), findsOneWidget);
    });

    testWidgets('hides the action when the payload has no trend id', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          NotificationTrendWidget(notification: trendLike(refId: '')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New like on your trend'), findsOneWidget);
      expect(find.text('View trend'), findsNothing);
    });

    testWidgets('uses the solid button style once read', (tester) async {
      await tester.pumpWidget(
        harness(
          NotificationTrendWidget(notification: trendLike(status: 'read')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Still actionable after being read.
      expect(find.text('View trend'), findsOneWidget);
    });

    testWidgets('deletes through the swipe action', (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        harness(
          NotificationTrendWidget(
            notification: trendLike(),
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(find.text('New like on your trend'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('shows a heart for a like', (tester) async {
      await tester.pumpWidget(
        harness(NotificationTrendWidget(notification: trendLike())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.mode_comment_outlined), findsNothing);
    });

    testWidgets('shows a comment icon for a comment', (tester) async {
      await tester.pumpWidget(
        harness(NotificationTrendWidget(notification: trendComment())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New comment on your trend'), findsOneWidget);
      expect(find.byIcon(Icons.mode_comment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('a comment notification still opens the trend', (tester) async {
      final pushed = <String>[];

      await tester.pumpWidget(
        harness(
          NotificationTrendWidget(notification: trendComment()),
          pushed: pushed,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('View trend'));
      await tester.pumpAndSettle();

      expect(pushed, ['/trends/trend_1']);
    });
  });
}
