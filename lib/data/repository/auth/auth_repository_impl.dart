import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/services/firebase_auth_service.dart';
import 'package:fashionista/domain/repository/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either> signInWithPhoneNumber(String mobileNumber) async {
    return await sl<FirebaseAuthService>().signInWithPhoneNumber(mobileNumber);
  }

  @override
  Future<void> signOut() {
   return sl<FirebaseAuthService>().signOut();
  }

  @override
  Future<Either> verifyPhoneNumberWithOtp(String mobileNumber, String otp) {
    return sl<FirebaseAuthService>().verifyPhoneNumberWithOtp(
      mobileNumber,
      otp,
    );
  }
}
