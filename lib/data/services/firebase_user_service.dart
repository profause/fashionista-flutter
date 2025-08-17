import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';

abstract class FirebaseUserService {
  Future<Either> fetchUserDetailsFromFirestore(String uid);
  Future<Either> updateUserDetails(User user);
  Future<Either> updateUserDisplayName(String name);
  Future<Either> updateUserEmail(String email);
  Future<Either> uploadProfileImage(CroppedFile croppedFile);
}

class FirebaseUserServiceImpl implements FirebaseUserService {
  @override
  Future<Either> fetchUserDetailsFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('users').doc(uid);
      DocumentSnapshot doc = await docRef.get();
      User user = User.fromJson(doc.data() as Map<String, dynamic>);
      //debugPrint(doc.data().toString());
      //debugPrint(user.toString());
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

  @override
  Future<Either<String, String>> uploadProfileImage(
    CroppedFile croppedFile,
  ) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left("User not logged in");
      }

      // Storage reference
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      // Metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uid': user.uid},
      );

      // Upload file
      final uploadTask = ref.putFile(File(croppedFile.path), metadata);
      await uploadTask;

      // Get download URL
      final link = await ref.getDownloadURL();

      // Update Firestore profile image URL
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profile_image': link},
      );

      // Also update FirebaseAuth profile photo
      await user.updatePhotoURL(link);

      return Right(link);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Upload failed');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
