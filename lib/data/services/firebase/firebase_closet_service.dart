import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseClosetService {
  Future<Either> addClosetItem(ClosetItemModel closetItem);
  Future<Either> updateClosetItem(ClosetItemModel closetItem);
  Future<Either> deleteClosetItem(ClosetItemModel closetItem);
  Future<Either<String, List<ClosetItemModel>>> findClosetItems(String uid);
  Future<Either> addOrRemoveFavouriteClosetItem(String uid);
  Future<Either> addOutfit(OutfitModel outfit);
  Future<Either> updateOutfit(OutfitModel outfit);
  Future<Either> deleteOutfit(OutfitModel outfit);
  Future<Either<String, List<OutfitModel>>> findOutfits(String uid);
  Future<Either<String, int>> getOutfitCount(String uid);
  Future<Either<String, int>> getClosetItemCount(String uid);
  Future<Either> addOrRemoveFavouriteOutfit(String uid);
}

class FirebaseClosetServiceImpl implements FirebaseClosetService {
  @override
  Future<Either> addClosetItem(ClosetItemModel closetItem) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('closets')
          .doc(closetItem.createdBy)
          .collection('closet_items')
          .doc(closetItem.uid)
          .set(closetItem.toJson(), SetOptions(merge: true));
      return Right(closetItem);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> addOrRemoveFavouriteClosetItem(String closetItemId) async {
    try {
      final us = FirebaseAuth.instance.currentUser;
      if (us == null) {
        return Left('User is not logged in');
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isFavourite;
      QuerySnapshot querySnapshot = await firestore
          .collection('closets')
          .doc(uid)
          .collection('closet_items')
          .where('uid', isEqualTo: closetItemId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Left('Closet item not found'); // or throw exception
      }
      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final closetItem = ClosetItemModel.fromJson(
        data,
      ).copyWith(uid: doc.reference.id);
      isFavourite = closetItem.isFavourite == null
          ? false
          : !closetItem.isFavourite!;

      await firestore
          .collection('closets')
          .doc(uid)
          .collection('closet_items')
          .doc(doc.reference.id)
          .update({'is_favourite': isFavourite});
      return Right(isFavourite);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> addOrRemoveFavouriteOutfit(String outfitId) async {
    try {
      final us = FirebaseAuth.instance.currentUser;
      if (us == null) {
        return Left('User is not logged in');
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isFavourite;
      QuerySnapshot querySnapshot = await firestore
          .collection('closets')
          .doc(uid)
          .collection('outfits')
          .where('uid', isEqualTo: outfitId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return Left('Closet item not found'); // or throw exception
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final outfit = OutfitModel.fromJson(data).copyWith(uid: doc.reference.id);
      isFavourite = outfit.isFavourite == null ? false : !outfit.isFavourite!;

      await firestore
          .collection('closets')
          .doc(uid)
          .collection('outfits')
          .doc(outfitId)
          .update({'is_favourite': isFavourite});
      return Right(isFavourite);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> addOutfit(OutfitModel outfit) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('closets')
          .doc(outfit.createdBy)
          .collection('outfits')
          .doc(outfit.uid)
          .set(outfit.toJson(), SetOptions(merge: true));
      return Right(outfit);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteClosetItem(ClosetItemModel closetItem) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore
          .collection('closets')
          .doc(closetItem.createdBy)
          .collection('closet_items')
          .doc(closetItem.uid)
          .delete();
      return const Right('successfully deleted'); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> deleteOutfit(OutfitModel outfit) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore
          .collection('closets')
          .doc(outfit.createdBy)
          .collection('outfits')
          .doc(outfit.uid)
          .delete();
      return const Right('successfully deleted'); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ClosetItemModel>>> findClosetItems(
    String uid,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('closets')
          .doc(uid)
          .collection('closet_items')
          //.where('created_by', isEqualTo: createdBy)
          .orderBy('created_at', descending: true)
          .get();

      final closetItems = querySnapshot.docs.map((doc) {
        final d = ClosetItemModel.fromJson(doc.data());
        return d;
      }).toList();

      //await importTrends(sampleTrendsData);
      return Right(closetItems);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<OutfitModel>>> findOutfits(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('closets')
          .doc(uid)
          .collection('outfits')
          //.where('created_by', isEqualTo: createdBy)
          .orderBy('created_at', descending: true)
          .get();

      final outfits = querySnapshot.docs.map((doc) {
        final d = OutfitModel.fromJson(doc.data());
        return d;
      }).toList();

      //await importTrends(sampleTrendsData);
      return Right(outfits);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateClosetItem(ClosetItemModel closetItem) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('closets')
          .doc(closetItem.createdBy)
          .collection('closet_items')
          .doc(closetItem.uid)
          .set(closetItem.toJson(), SetOptions(merge: true));
      return Right(closetItem);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateOutfit(OutfitModel outfit) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('closets')
          .doc(outfit.createdBy)
          .collection('outfits')
          .doc(outfit.uid)
          .set(outfit.toJson(), SetOptions(merge: true));
      return Right(outfit);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either<String, int>> getClosetItemCount(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('closets')
          .doc(uid)
          .collection('closet_items')
          .count()
          .get();

      final outfitCount = querySnapshot.count;

      //await importTrends(sampleTrendsData);
      return Right(outfitCount ?? 0);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, int>> getOutfitCount(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('closets')
          .doc(uid)
          .collection('outfits')
          .count()
          .get();

      final outfitCount = querySnapshot.count;

      //await importTrends(sampleTrendsData);
      return Right(outfitCount ?? 0);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
