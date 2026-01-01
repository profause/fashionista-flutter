import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

abstract class FirebaseDesignersService {
  Future<Either<String, List<Designer>>> findDesigners();
  Future<Either<String, List<Designer>>> findDesignersWithFilter(
    int limit,
    String orderBy,
  );
  Future<Either<String, List<Designer>>> findDesignersAfterCache(
    int lastCacheTimestamp,
  );
  Future<Either> addDesignerToFirestore(Designer designer);
  Future<Either> updateDesignerToFirestore(Designer designer);
  Future<Either> deleteDesignerById(String uid);
  Future<Either<String, Designer>> findDesignerById(String uid);
  Future<Either> uploadBannerImage(String uid, CroppedFile croppedFile);
  Future<Either> uploadBannerImageToCloudinary(
    String uid,
    CroppedFile croppedFile,
  );
  Future<Either> addOrRemoveFavouriteDesigner(String designerId);
  Future<bool> isFavouriteDesigner(String designerId);
  Future<Either> fetchFavouriteDesigners(List<String> designerIds);
  Future<Either<String, List<CommentModel>>> findDesignerFeedback(
    String designerId,
  );

  Future<Either> addFeedbackForDesigner(CommentModel comment);
  Future<Either> deleteFeedbackForDesigner(CommentModel comment);

  Future<Either<String, List<DesignerReviewModel>>> findDesignerReviews(
    String designerId,
  );
  Future<Either> addDesignerReview(DesignerReviewModel review);
  Future<Either> deleteDesignerReview(DesignerReviewModel review);
}

class FirebaseDesignersServiceImpl implements FirebaseDesignersService {
  @override
  Future<Either> addDesignerToFirestore(Designer designer) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('designers')
          .doc(designer.uid)
          .set(designer.toJson(), SetOptions(merge: true));
      return Right(designer);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteDesignerById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete the document with the given uid
      await firestore.collection('designers').doc(uid).delete();
      return const Right(
        'successfully deleted designer',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<Designer>>> findDesigners() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('designers')
          //.where('created_by', isEqualTo: uid)
          .orderBy('created_date', descending: true)
          .get();
      // Map each document to a Designer
      // Await all async maps
      final designers = await Future.wait(
        querySnapshot.docs.map((doc) async {
          bool isFavourite = await isFavouriteDesigner(doc.reference.id);
          final d = Designer.fromJson(doc.data());
          return d.copyWith(isFavourite: isFavourite);
        }),
      );
      //await sl<HiveDesignersService>().insertItems(items: designers);
      return Right(designers);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<Designer>>> findDesignersWithFilter(
    int limit,
    String orderBy,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('designers')
          .orderBy(orderBy, descending: true)
          .limit(limit)
          .get();
      // Map each document to a Designer
      // Await all async maps
      final designers = await Future.wait(
        querySnapshot.docs.map((doc) async {
          bool isFavourite = await isFavouriteDesigner(doc.reference.id);
          final d = Designer.fromJson(doc.data());
          return d.copyWith(isFavourite: isFavourite);
        }),
      );
      //await sl<HiveDesignersService>().insertItems(items: designers);
      return Right(designers);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<Designer>>> findDesignersAfterCache(
    int lastCacheTimestamp,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('designers')
          //.where('created_by', isEqualTo: uid)
          .orderBy('created_date', descending: true)
          .get();
      // Map each document to a Designer
      // Await all async maps
      final designers = await Future.wait(
        querySnapshot.docs.map((doc) async {
          bool isFavourite = await isFavouriteDesigner(doc.reference.id);
          final d = Designer.fromJson(doc.data());
          return d.copyWith(isFavourite: isFavourite);
        }),
      );
      //await sl<HiveDesignersService>().insertItems(items: designers);
      return Right(designers);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Designer>> findDesignerById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('designers').doc(uid);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        //fetch user instead
        docRef = firestore.collection('users').doc(uid);
        doc = await docRef.get();
        User user = User.fromJson(doc.data() as Map<String, dynamic>);
        Designer designer = Designer.empty().copyWith(
          name: user.fullName,
          mobileNumber: user.mobileNumber,
          uid: user.uid,
          profileImage: user.profileImage,
          bannerImage: user.bannerImage,
          createdDate: DateTime.now(),
        );

        return Right(designer);
      }

      Designer designer = Designer.fromJson(doc.data() as Map<String, dynamic>);

      return Right(designer);
    } on FirebaseException catch (e) {
      return Left(e.message.toString());
    }
  }

  @override
  Future<Either> updateDesignerToFirestore(Designer designer) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('designers')
          .doc(designer.uid)
          .set(designer.toJson(), SetOptions(merge: true));
      return Right(designer);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either<String, String>> uploadBannerImageToCloudinary(
    String uid,
    CroppedFile croppedFile,
  ) async {
    try {
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

      final fileName = "$uid.jpg";
      final publicId = uid;

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

      try {
        await Future.wait([
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'banner_image': link,
          }),
          FirebaseFirestore.instance.collection('designers').doc(uid).update({
            'banner_image': link,
          }),
        ]);
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
    String uid,
    CroppedFile croppedFile,
  ) async {
    try {
      // final user = firebase_auth.FirebaseAuth.instance.currentUser;
      // if (user == null) {
      //   return const Left("User not logged in");
      // }

      // Storage reference
      final ref = FirebaseStorage.instance
          .ref()
          .child('banner_images')
          .child('$uid.jpg');

      // Metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uid': uid},
      );

      // Upload file
      final uploadTask = ref.putFile(File(croppedFile.path), metadata);
      await uploadTask;

      // Get download URL
      final link = await ref.getDownloadURL();

      // Update Firestore profile image URL
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'banner_image': link,
      });

      try {
        // Update Firestore profile image URL
        await FirebaseFirestore.instance
            .collection('designers')
            .doc(uid)
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
  Future<Either> addOrRemoveFavouriteDesigner(String designerId) async {
    try {
      String uid = 'La9DWF9gv9YEqpWzTrYVBiUzGHf1';
      final us = firebase_auth.FirebaseAuth.instance.currentUser;
      if (us != null) {
        uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      }

      final firestore = FirebaseFirestore.instance;
      late bool isFavourite;
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('favourite_designers')
          .where('designer_id', isEqualTo: designerId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('favourite_designers')
            .doc(designerId)
            .set({
              'designer_id': designerId,
              'created_at': Timestamp.now(),
            }, SetOptions(merge: true));
        isFavourite = true;
      } else {
        await querySnapshot.docs.first.reference.delete();
        isFavourite = false;
      }
      return Right(isFavourite);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<bool> isFavouriteDesigner(String designerId) async {
    try {
      String uid = '';
      final us = firebase_auth.FirebaseAuth.instance.currentUser;
      if (us != null) {
        uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      }
      final firestore = FirebaseFirestore.instance;
      late bool isFavourite;
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('favourite_designers')
          .where('designer_id', isEqualTo: designerId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isFavourite = false;
        return isFavourite;
      } else {
        isFavourite = true;
        return isFavourite;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either> fetchFavouriteDesigners(List<String> designerIds) async {
    try {
      if (designerIds.isEmpty) return Right([]);

      final chunks = <List<String>>[];
      for (var i = 0; i < designerIds.length; i += 10) {
        chunks.add(
          designerIds.sublist(
            i,
            i + 10 > designerIds.length ? designerIds.length : i + 10,
          ),
        );
      }
      final results = await Future.wait(
        chunks.map((chunk) {
          return FirebaseFirestore.instance
              .collection('designers')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
        }),
      );

      final designers = results
          .expand((querySnapshot) => querySnapshot.docs)
          .map((doc) => Designer.fromJson(doc.data()))
          .toList();

      return Right(designers);
    } on FirebaseException catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CommentModel>>> findDesignerFeedback(
    String designerId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('designer_feedback')
          .where('ref_id', isEqualTo: designerId)
          .orderBy('created_at', descending: true)
          .get();
      // Map each document to a comment
      final comments = querySnapshot.docs.map((doc) {
        final d = CommentModel.fromJson(doc.data());
        return d.copyWith(uid: doc.reference.id);
      }).toList();
      return Right(comments);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> addFeedbackForDesigner(CommentModel comment) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('designer_feedback')
          .doc(comment.uid)
          .set(comment.toJson(), SetOptions(merge: true));
      return Right(comment);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteFeedbackForDesigner(CommentModel comment) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore.collection('designer_feedback').doc(comment.uid).delete();
      return const Right(
        'successfully deleted comment',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> addDesignerReview(DesignerReviewModel review) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('designer_reviews')
          .doc(review.uid)
          .set(review.toJson(), SetOptions(merge: true));
      return Right(review);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteDesignerReview(DesignerReviewModel review) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore.collection('designer_reviews').doc(review.uid).delete();
      return const Right('successfully deleted review'); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<DesignerReviewModel>>> findDesignerReviews(
    String designerId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('designer_reviews')
          .where('ref_id', isEqualTo: designerId)
          .orderBy('created_at', descending: true)
          .get();
      // Map each document to a comment
      final reviews = querySnapshot.docs.map((doc) {
        final d = DesignerReviewModel.fromJson(doc.data());
        return d.copyWith(uid: doc.reference.id);
      }).toList();
      return Right(reviews);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
