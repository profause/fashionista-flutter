import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<Either> signInWithPhoneNumber(String mobileNumber);
  Future<Either> verifyPhoneNumberWithOtp(PhoneAuthCredential credential);
  Future<void> signOut();
}