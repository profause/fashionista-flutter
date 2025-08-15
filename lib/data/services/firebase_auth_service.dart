import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class FirebaseAuthService {
  Future<Either> signInWithPhoneNumber(String mobileNumber);
  Future<Either> verifyPhoneNumberWithOtp(String mobileNumber, String otp);
  Future<void> signOut();
}

class FirebaseAuthServiceImpl implements FirebaseAuthService {
  @override
  Future<Either> signInWithPhoneNumber(String mobileNumber) async {
    try {
      String response = "success";
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: mobileNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (phoneAuthCredential) {
          response = "verificationCompleted";
        },
        verificationFailed: (error) {
          response = error.toString();
        },
        codeSent: (String verificationId, int? resendToken) {
          response = "otp sent";
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("Timeout");
          response = "timeout";
        },
      );

      return Right(response);
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      return Left(e.message);
    }
  }

  @override
  Future<Either> verifyPhoneNumberWithOtp(
    String mobileNumber,
    String otpString,
  ) async {
    try {
      String response = "success";
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: otpString,
        smsCode: otpString,
      );
      await FirebaseAuth.instance.signInWithCredential(credential).then((
        onValue,
      ) {
        return Right(onValue.user);
      });
      return Right(response);
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      return Left(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
