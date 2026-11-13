import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/presentation/screens/trends/widgets/fashion_interest_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FashionInterestModel interest(String name, int posts) {
  return FashionInterestModel(
    category: 'category',
    name: name,
    numberOfPosts: posts,
  );
}

Future<void> pumpPanel(WidgetTester tester, FashionInterestPanel panel) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: fashionistaLightTheme,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: panel),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('lists interests with their post counts', (tester) async {
    final tapped = <String>[];

    await pumpPanel(
      tester,
      FashionInterestPanel(
        interests: [interest('summer', 1200), interest('linen', 4)],
        onInterestTap: (interest) => tapped.add(interest.name),
      ),
    );

    expect(find.text('All interests'), findsOneWidget);
    expect(find.text('summer'), findsOneWidget);
    expect(find.text('1.2K posts'), findsOneWidget);
    expect(find.text('linen'), findsOneWidget);
    expect(find.text('4 posts'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fashion-interest-summer')));

    expect(tapped, ['summer']);
  });

  testWidgets('shows the active query in the header', (tester) async {
    await pumpPanel(
      tester,
      FashionInterestPanel(
        interests: [interest('summer', 20)],
        query: 'sum',
        onInterestTap: (_) {},
      ),
    );

    expect(find.text('Matching "sum"'), findsOneWidget);
  });

  testWidgets('shows a loading state', (tester) async {
    await pumpPanel(
      tester,
      FashionInterestPanel(
        interests: const [],
        isLoading: true,
        onInterestTap: (_) {},
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading interests…'), findsOneWidget);
  });

  testWidgets('shows an error with retry', (tester) async {
    var retried = false;

    await pumpPanel(
      tester,
      FashionInterestPanel(
        interests: const [],
        error: 'offline',
        onRetry: () => retried = true,
        onInterestTap: (_) {},
      ),
    );

    expect(find.text('Could not load interests'), findsOneWidget);

    await tester.tap(find.text('Retry'));

    expect(retried, isTrue);
  });

  testWidgets('shows an empty message for the query', (tester) async {
    await pumpPanel(
      tester,
      FashionInterestPanel(
        interests: const [],
        query: 'zzz',
        onInterestTap: (_) {},
      ),
    );

    expect(find.text('No interests match "zzz"'), findsOneWidget);
  });
}
