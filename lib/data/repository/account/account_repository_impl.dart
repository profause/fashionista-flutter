import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/account/account_deletion_result.dart';
import 'package:fashionista/data/services/firebase/firebase_account_service.dart';
import 'package:fashionista/domain/repository/account/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<Either<String, AccountDeletionResult>> deleteAccount({
    required String confirmation,
  }) {
    return sl<FirebaseAccountService>().deleteMyAccount(
      confirmation: confirmation,
    );
  }
}
