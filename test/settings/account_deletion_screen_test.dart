import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/core/auth/account_deletion_state.dart';
import 'package:fashionista/data/models/account/account_deletion_result.dart';
import 'package:fashionista/domain/repository/account/account_repository.dart';
import 'package:fashionista/domain/usecases/account/delete_account_usecase.dart';
import 'package:fashionista/presentation/screens/settings/account_deletion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAccountRepository implements AccountRepository {
  int calls = 0;
  Completer<Either<String, AccountDeletionResult>>? gate;
  Either<String, AccountDeletionResult> result = const Left(
    'Could not delete your account. Please try again.',
  );

  @override
  Future<Either<String, AccountDeletionResult>> deleteAccount({
    required String confirmation,
  }) async {
    calls += 1;
    if (gate != null) return gate!.future;
    return result;
  }
}

void main() {
  late _FailingAccountRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    _FailingAccountRepository? repositoryOverride,
    Future<void> Function(BuildContext)? cleanup,
    void Function(BuildContext)? onDeletionComplete,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    repository = repositoryOverride ?? _FailingAccountRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AccountDeletionScreen(
          deleteAccountUsecase: DeleteAccountUsecase(repository: repository),
          deletionState: AccountDeletionState(),
          privacyPolicyUrl: 'https://example.com/privacy',
          cleanupOverride: cleanup ?? (_) async {},
          onDeletionComplete: onDeletionComplete,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('requires the exact DELETE confirmation', (tester) async {
    await pumpScreen(tester);

    final button = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('shows consequences and a privacy policy link', (tester) async {
    await pumpScreen(tester);

    expect(
      find.text('This will permanently delete your account'),
      findsOneWidget,
    );
    expect(
      find.text(
        'This cannot be undone. The following data will be '
        'removed from Fashionista:',
      ),
      findsOneWidget,
    );
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);
  });

  testWidgets('shows progress, then an error with retry', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.ensureVisible(find.text('Delete my account'));

    final gate = Completer<Either<String, AccountDeletionResult>>();
    repository.gate = gate;
    await tester.tap(find.text('Delete my account'));
    await tester.pump();

    expect(find.text('Deleting your account…'), findsOneWidget);

    gate.complete(
      const Left('Could not delete your account. Please try again.'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not delete your account. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(repository.calls, 1);

    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
  });

  testWidgets('does not submit without confirmation', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('cleans up and navigates after a successful deletion', (
    tester,
  ) async {
    final successRepository = _FailingAccountRepository()
      ..result = const Right(AccountDeletionResult(completedSteps: 10));
    var cleaned = false;
    var navigated = false;

    await pumpScreen(
      tester,
      repositoryOverride: successRepository,
      cleanup: (_) async => cleaned = true,
      onDeletionComplete: (_) => navigated = true,
    );

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(find.text('Delete my account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(cleaned, isTrue);
    expect(navigated, isTrue);
  });
}
