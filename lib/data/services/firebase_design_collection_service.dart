import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class FirebaseDesignCollectionService {
  Future<Either> fetchDesignCollections();
  Future<Either> findDesignCollections(String createdBy);
  Future<Either> addDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  );
  Future<Either> updateDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  );
  Future<Either> findDesignCollectionById(String uid);
  Future<Either> deleteDesignCollectionById(String uid);
  Future<bool> isBookmarkedDesignCollection(String uid);
  Future<Either> addOrRemoveBookmarkDesign(String uid);
  Future<Either> fetchBookmarkedDesignCollections(List<String> uids);
}

class FirebaseDesignCollectionServiceImpl
    implements FirebaseDesignCollectionService {
  @override
  Future<Either> fetchDesignCollections() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('design_collections')
          //.where('created_by', isEqualTo: createdBy)
          .get();
      // Map each document to a DesignCollection
      final designCollection = querySnapshot.docs.map((doc) async {
        //bool isFavourite = await isFavouriteDesigner(doc.reference.id);
        final d = DesignCollectionModel.fromJson(doc.data());
        return d; //.copyWith(isFavourite: isFavourite);
      }).toList();
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> addDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('design_collections')
          .doc(designCollection.uid)
          .set(designCollection.toJson(), SetOptions(merge: true));
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteDesignCollectionById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete the document with the given uid
      await firestore.collection('design_collections').doc(uid).delete();
      return const Right(
        'successfully deleted design collection',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> findDesignCollectionById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore
          .collection('design_collections')
          .doc(uid);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('Design Collection not found');
      }

      DesignCollectionModel designCollection = DesignCollectionModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('design_collections')
          .doc(designCollection.uid)
          .set(designCollection.toJson(), SetOptions(merge: true));
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> findDesignCollections(String createdBy) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('design_collections')
          .where('created_by', isEqualTo: createdBy)
          .get();
      // Map each document to a DesignCollection
      final designCollection = querySnapshot.docs.map((doc) async {
        //bool isBookmarked = await isBookmarkedDesignCollection(doc.reference.id);
        final d = DesignCollectionModel.fromJson(doc.data());
        return d; //.copyWith(isBookmarked: isBookmarked);
      }).toList();
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> addOrRemoveBookmarkDesign(String designCollectionId) async {
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
          .where('design_collection_id', isEqualTo: designCollectionId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('bookmarked_design_collections')
            .doc(designCollectionId)
            .set({
              'design_collection_id': designCollectionId,
              'created_at': Timestamp.now(),
            }, SetOptions(merge: true));
        isBookmarked = true;
      } else {
        await querySnapshot.docs.first.reference.delete();
        isBookmarked = false;
      }
      return Right(isBookmarked);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> fetchBookmarkedDesignCollections(List<String> uids) async {
    try {
      if (uids.isEmpty) return Right([]);

      final chunks = <List<String>>[];
      for (var i = 0; i < uids.length; i += 10) {
        chunks.add(
          uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10),
        );
      }
      final results = await Future.wait(
        chunks.map((chunk) {
          return FirebaseFirestore.instance
              .collection('design_collections')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
        }),
      );

      final designers = results
          .expand((querySnapshot) => querySnapshot.docs)
          .map((doc) => DesignCollectionModel.fromJson(doc.data()))
          .toList();

      return Right(designers);
    } on FirebaseException catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> isBookmarkedDesignCollection(String designCollectionId) async {
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
          .where('design_collection_id', isEqualTo: designCollectionId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isBookmarked = false;
      } else {
        isBookmarked = true;
      }
      return isBookmarked;
    } catch (e) {
      return false;
    }
  }
}
