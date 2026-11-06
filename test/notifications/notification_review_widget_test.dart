import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_review_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

NotificationModel review({
  String? type = 'review',
  String status = 'new',
  Map<String, String>? data = const {
    'designer_id': 'designer_3',
    'rating': '4',
  },
}) {
  return NotificationModel(
    uid: 'designer__review__review_9',
    refId: 'review_9',
    refType: 'designer_review',
    title: 'New review',
    description: 'Ama Boateng rated you 4 stars: "Beautiful work."',
    type: type ?? 'review',
    createdAt: DateTime.now()
        .subtract(const Duration(minutes: 5))
        .millisecondsSinceEpoch,
    status: status,
    to: 'designer_3',
    event: 'review_received',
    data: data,
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
        path: '/designers/:id',
        builder: (_, state) {
          pushed?.add('/designers/${state.pathParameters['id']}');
          return const Scaffold(body: Text('designer profile'));
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
  group('NotificationReviewWidget', () {
    testWidgets('renders the review and the star rating', (tester) async {
      await tester.pumpWidget(
        harness(NotificationReviewWidget(notification: review())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New review'), findsOneWidget);
      expect(
        find.text('Ama Boateng rated you 4 stars: "Beautiful work."'),
        findsOneWidget,
      );
      expect(find.text('View profile'), findsOneWidget);

      // Four filled stars, one outline.
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(1));
    });

    testWidgets('opens the designer profile', (tester) async {
      final pushed = <String>[];
      var tapped = false;

      await tester.pumpWidget(
        harness(
          NotificationReviewWidget(
            notification: review(),
            onTap: () => tapped = true,
          ),
          pushed: pushed,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('View profile'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue, reason: 'tapping must mark the row as read');
      expect(pushed, ['/designers/designer_3']);
      expect(find.text('designer profile'), findsOneWidget);
    });

    testWidgets('hides the star row when the payload has no rating', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          NotificationReviewWidget(
            notification: review(
              data: const {'designer_id': 'designer_3'},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
      expect(find.text('New review'), findsOneWidget);
    });

    testWidgets('hides the action when the designer id is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          NotificationReviewWidget(notification: review(data: const {})),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New review'), findsOneWidget);
      expect(find.text('View profile'), findsNothing);
    });

    testWidgets('ignores an out-of-range rating', (tester) async {
      await tester.pumpWidget(
        harness(
          NotificationReviewWidget(
            notification: review(
              data: const {'designer_id': 'designer_3', 'rating': '9'},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('New review'), findsOneWidget);
    });

    testWidgets('deletes through the swipe action', (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        harness(
          NotificationReviewWidget(
            notification: review(),
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(find.text('New review'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
