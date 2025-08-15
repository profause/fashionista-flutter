import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/widgets.dart';

abstract class FirebaseUserService {
  Future<Either> fetchUserDetailsFromFirestore(String uid);
  Future<Either> updateUserDetails(User user);
  Future<Either> updateUserDisplayName(String name);
  Future<Either> updateUserEmail(String email);
}

class FirebaseUserServiceImpl implements FirebaseUserService {
  @override
  Future<Either> fetchUserDetailsFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('users').doc(uid);
      DocumentSnapshot doc = await docRef.get();
      User user = User.fromJson(doc.data() as Map<String, dynamic>);
      debugPrint(doc.data().toString());
      debugPrint(user.toString());
      return Right(user);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateUserDetails(User user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
      return Right(user);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateUserEmail(String email) async {
    try {
      firebase_auth.User? user =
          firebase_auth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        return const Left('No user is currently signed in');
      }
      await user.verifyBeforeUpdateEmail(email);
      await user.reload(); // Refresh to get updated data
      final updatedUser = firebase_auth.FirebaseAuth.instance.currentUser;

      return Right(updatedUser!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Unknown error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateUserDisplayName(String name) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left('No user is currently signed in');
      }
      await user.updateDisplayName(name);
      await user.reload();
      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Unknown error');
    }
  }
}
