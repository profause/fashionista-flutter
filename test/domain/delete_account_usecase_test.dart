import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/account/account_deletion_result.dart';
import 'package:fashionista/domain/repository/account/account_repository.dart';
import 'package:fashionista/domain/usecases/account/delete_account_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAccountRepository implements AccountRepository {
  String? confirmation;
  Either<String, AccountDeletionResult> result = const Right(
    AccountDeletionResult(completedSteps: 10),
  );

  @override
  Future<Either<String, AccountDeletionResult>> deleteAccount({
    required String confirmation,
  }) async {
    this.confirmation = confirmation;
    return result;
  }
}

void main() {
  test('passes the typed confirmation to the repository', () async {
    final repository = _FakeAccountRepository();
    final usecase = DeleteAccountUsecase(repository: repository);

    final result = await usecase(
      const DeleteAccountParams(confirmation: 'DELETE'),
    );

    expect(repository.confirmation, 'DELETE');
    expect(result.isRight(), isTrue);
    expect(
      result.getOrElse(() => const AccountDeletionResult()).completedSteps,
      10,
    );
  });

  test('returns callable errors unchanged', () async {
    final repository = _FakeAccountRepository()
      ..result = const Left('Could not delete your account.');
    final usecase = DeleteAccountUsecase(repository: repository);

    final result = await usecase(
      const DeleteAccountParams(confirmation: 'DELETE'),
    );

    expect(result, const Left('Could not delete your account.'));
  });
}
