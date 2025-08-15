import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either> signInWithPhoneNumber(String mobileNumber);
  Future<Either> verifyPhoneNumberWithOtp(String mobileNumber,String otp);
  Future<void> signOut();
}