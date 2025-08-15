import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/auth/auth_repository.dart';

class VerifyOtpUsecase implements Usecase<Either,dynamic>{
  @override
  Future<Either> call(dynamic params) {
    return sl<AuthRepository>().verifyPhoneNumberWithOtp(params);
  }
}