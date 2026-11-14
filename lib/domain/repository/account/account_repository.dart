import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/account/account_deletion_result.dart';

abstract class AccountRepository {
  Future<Either<String, AccountDeletionResult>> deleteAccount({
    required String confirmation,
  });
}
