import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/account/account_deletion_result.dart';
import 'package:fashionista/domain/repository/account/account_repository.dart';

class DeleteAccountParams {
  final String confirmation;

  const DeleteAccountParams({required this.confirmation});
}

class DeleteAccountUsecase
    implements
        Usecase<Either<String, AccountDeletionResult>, DeleteAccountParams> {
  final AccountRepository? _repository;

  DeleteAccountUsecase({AccountRepository? repository})
    : _repository = repository;

  @override
  Future<Either<String, AccountDeletionResult>> call(
    DeleteAccountParams params,
  ) {
    return (_repository ?? sl<AccountRepository>()).deleteAccount(
      confirmation: params.confirmation,
    );
  }
}
