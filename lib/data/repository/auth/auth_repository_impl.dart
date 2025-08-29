import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/services/firebase/firebase_auth_service.dart';
import 'package:fashionista/domain/repository/auth/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Future<Either> verifyPhoneNumberWithOtp(PhoneAuthCredential credential) async{
    return sl<FirebaseAuthService>().verifyPhoneNumberWithOtp(
     credential
    );
  }
}
