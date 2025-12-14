import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

abstract class FirebaseUserService {
  Future<Either<String, User>> fetchUserDetailsFromFirestore(String uid);
  Future<Either<String, User>> findUserByMobileNumber(String mobileNumber);
  Future<Either> updateUserDetails(User user);
  Future<Either> updateUserDisplayName(String name);
  Future<Either> updateUserEmail(String email);
  Future<Either> uploadProfileImage(CroppedFile croppedFile);
  Future<Either> uploadProfileImageToCloudinary(CroppedFile croppedFile);
  Future<Either> uploadBannerImage(CroppedFile croppedFile);
  Future<Either> uploadBannerImageToCloudinary(CroppedFile croppedFile);
  Future<Either> findFavouriteDesignerIds();
  Future<bool> hasBookmarkedDesignCollection();
  Future<Either> findBookmarkedDesignCollectionIds();
}

class FirebaseUserServiceImpl implements FirebaseUserService {
  @override
  Future<Either<String, User>> fetchUserDetailsFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('users').doc(uid);
      DocumentSnapshot doc = await docRef.get();
      if(doc.data() == null){
        return Right(User.empty());
      }
      User user = User.fromJson(doc.data() as Map<String, dynamic>);
      return Right(user);
    } on FirebaseException catch (e) {
      return Left(e.toString());
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

  @override
  Future<Either<String, String>> uploadProfileImageToCloudinary(
    CroppedFile croppedFile,
  ) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left("User not logged in");
      }
      final bytes = await croppedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      CloudinaryConfig config = CloudinaryConfig.fromUri(
        appConfig.get('cloudinary_url'),
      );
      final profileImageFolder = appConfig.get(
        'cloudinary_profile_images_folder',
      );
      final baseFolder = appConfig.get('cloudinary_base_folder');
      final cloudinary = Cloudinary.fromConfiguration(config);

      final fileName = "${user.uid}.jpg";
      final publicId = user.uid;

      final transformation = Transformation()
          .resize(Resize.auto().width(360).height(360).aspectRatio(1 / 1))
          //.addTransformation('q_60')
          .addTransformation('q_auto:good');

      final uploadResult = await cloudinary.uploader().upload(
        'data:image/jpeg;base64,$base64Image',
        params: UploadParams(
          filename: fileName,
          publicId: publicId,
          useFilename: true,
          folder: '$baseFolder/$profileImageFolder',
          uploadPreset: 'ml_default',
          type: 'image/jpeg',
          transformation: transformation,
        ),
      );

      if (uploadResult == null) {
        debugPrint("Upload failed — no response from Cloudinary");
        throw Exception("Upload failed — no response from Cloudinary");
      }
      if (uploadResult.error != null) {
        debugPrint("Upload failed: ${uploadResult.error!.message}");
        throw Exception(uploadResult.error!.message);
      }

      final url = uploadResult.data?.secureUrl;
      if (url == null) {
        debugPrint("Upload failed — no URL returned");
        throw Exception("Upload failed — no URL returned");
      }
      // Get download URL
      final link = url;

      // Update Firestore profile image URL

      try {
        await Future.wait([
          FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'profile_image': link,
          }),
          // Update Firestore profile image URL
          FirebaseFirestore.instance
              .collection('designers')
              .doc(user.uid)
              .update({'profile_image': link}),
        ]);
      } catch (e) {
        debugPrint(e.toString());
      }

      // Also update FirebaseAuth profile photo
      await user.updatePhotoURL(link);

      return Right(link);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Upload failed');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> uploadBannerImageToCloudinary(
    CroppedFile croppedFile,
  ) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left("User not logged in");
      }
      final bytes = await croppedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      CloudinaryConfig config = CloudinaryConfig.fromUri(
        appConfig.get('cloudinary_url'),
      );
      final bannerImageFolder = appConfig.get(
        'cloudinary_banner_images_folder',
      );
      final baseFolder = appConfig.get('cloudinary_base_folder');
      final cloudinary = Cloudinary.fromConfiguration(config);

      final fileName = "${user.uid}.jpg";
      final publicId = user.uid;

      final transformation = Transformation()
          .resize(Resize.auto().height(240).aspectRatio(16 / 9))
          //.addTransformation('q_60')
          .addTransformation('q_auto:good');

      final uploadResult = await cloudinary.uploader().upload(
        'data:image/jpeg;base64,$base64Image',
        params: UploadParams(
          filename: fileName,
          publicId: publicId,
          useFilename: true,
          folder: '$baseFolder/$bannerImageFolder',
          uploadPreset: 'ml_default',
          type: 'image/jpeg',
          transformation: transformation,
        ),
      );

      if (uploadResult == null) {
        debugPrint("Upload failed — no response from Cloudinary");
        throw Exception("Upload failed — no response from Cloudinary");
      }
      if (uploadResult.error != null) {
        debugPrint("Upload failed: ${uploadResult.error!.message}");
        throw Exception(uploadResult.error!.message);
      }

      final url = uploadResult.data?.secureUrl;
      if (url == null) {
        debugPrint("Upload failed — no URL returned");
        throw Exception("Upload failed — no URL returned");
      }
      // Get download URL
      final link = url;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'banner_image': link},
      );

      try {
        // Update Firestore profile image URL
        await FirebaseFirestore.instance
            .collection('designers')
            .doc(user.uid)
            .update({'banner_image': link});
      } catch (e) {
        debugPrint(e.toString());
      }

      return Right(link);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Upload failed');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> uploadBannerImage(
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
          .child('banner_images')
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
        {'banner_image': link},
      );

      try {
        // Update Firestore profile image URL
        await FirebaseFirestore.instance
            .collection('designers')
            .doc(user.uid)
            .update({'banner_image': link});
      } catch (e) {
        debugPrint(e.toString());
      }

      return Right(link);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Upload failed');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> findFavouriteDesignerIds() async {
    try {
      String uid = 'La9DWF9gv9YEqpWzTrYVBiUzGHf1';
      final us = firebase_auth.FirebaseAuth.instance.currentUser;
      if (us != null) {
        uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      }
      final firestore = FirebaseFirestore.instance;
      final designerIdsQuery = await firestore
          .collection('users')
          .doc(uid)
          .collection('favourite_designers')
          .get();
      final designerIds = designerIdsQuery.docs
          .map((e) => e.data()['designer_id'].toString())
          .toList();
      return Right(designerIds);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> findBookmarkedDesignCollectionIds() async {
    try {
      String uid = 'La9DWF9gv9YEqpWzTrYVBiUzGHf1';
      final us = firebase_auth.FirebaseAuth.instance.currentUser;
      if (us != null) {
        uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      }
      final firestore = FirebaseFirestore.instance;
      final designerIdsQuery = await firestore
          .collection('users')
          .doc(uid)
          .collection('favourite_designers')
          .get();
      final designerIds = designerIdsQuery.docs
          .map((e) => e.data()['designer_id'].toString())
          .toList();
      return Right(designerIds);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<bool> hasBookmarkedDesignCollection() async {
    try {
      String uid = 'La9DWF9gv9YEqpWzTrYVBiUzGHf1';
      final us = firebase_auth.FirebaseAuth.instance.currentUser;
      if (us != null) {
        uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      }
      final firestore = FirebaseFirestore.instance;
      late bool isBookmarked;
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('bookmarked_design_collections')
          //.where('design_collection_id', isEqualTo: designCollectionId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isBookmarked = false;
        return isBookmarked;
      } else {
        isBookmarked = true;
        return isBookmarked;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<String, User>> findUserByMobileNumber(
    String mobileNumber,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .where('mobile_number', isEqualTo: mobileNumber)
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return Left('No user found');
      }
      User user = User.fromJson(
        querySnapshot.docs.first.data() as Map<String, dynamic>,
      );
      return Right(user);
    } on FirebaseException catch (e) {
      return Left(e.message!);
    }
  }
}
