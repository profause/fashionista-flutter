import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/profile/models/user.dart' as userModel;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class FirebaseAuthService {
  Future<Either> signInWithPhoneNumber(String mobileNumber);
  Future<Either> signInWithPhoneNumber2(
    String mobileNumber,
    ValueNotifier<String> sendCode,
  );
  Future<Either> verifyPhoneNumberWithOtp(PhoneAuthCredential credential);
  Future<void> signOut();
}

class FirebaseAuthServiceImpl implements FirebaseAuthService {
  //final ValueNotifier<String> sendCode = ValueNotifier('');

  @override
  Future<Either> signInWithPhoneNumber2(
    String mobileNumber,
    ValueNotifier<String> sendCode,
  ) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: mobileNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (phoneAuthCredential) {
          //response = "verificationCompleted";
        },
        verificationFailed: (error) {
          //response = error.toString();
          Left(error.toString());
        },
        codeSent: (String verificationId, int? resendToken) {
          sendCode.value = verificationId;
          debugPrint("Code sent $verificationId");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("Timeout");
          Right(verificationId);
        },
      );
      return const Right('code sent');
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      return Left(e.message);
    }
  }

  @override
  Future<Either<String, User?>> verifyPhoneNumberWithOtp(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      return Right(userCredential.user);
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      return Left(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<Either<String, String>> signInWithPhoneNumber(
    String mobileNumber,
  ) async {
    final completer = Completer<Either<String, String>>();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: mobileNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (phoneAuthCredential) {
          // Auto-verification case, optional to handle
        },
        verificationFailed: (error) {
          completer.complete(Left(error.message ?? 'Verification failed'));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("Code sent: $verificationId");
          completer.complete(Right(verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("Timeout: $verificationId");
          // You can decide if you want to return timeout here
        },
      );

      return completer.future;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      return Left(e.message ?? 'Unknown error');
    }
  }
}
