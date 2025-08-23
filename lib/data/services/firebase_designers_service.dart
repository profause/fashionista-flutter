import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/models/user.dart';

abstract class FirebaseDesignersService {
  Future<Either> fetchDesigners();
  Future<Either> addDesignerToFirestore(Designer designer);
  Future<Either> updateDesignerToFirestore(Designer designer);
  Future<Either> deleteDesignerById(String uid);
  Future<Either> findDesignerById(String uid);
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
  Future<Either> fetchDesigners() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('designers')
          //.where('created_by', isEqualTo: uid)
          .get();
      // Map each document to a Designer
      final designers = querySnapshot.docs
          .map((doc) => Designer.fromJson(doc.data()))
          .toList();
      return Right(designers);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> findDesignerById(String uid) async {
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
        );

        //debugPrint(designer.toString());
        return Right(designer);
      }

      Designer designer = Designer.fromJson(doc.data() as Map<String, dynamic>);

      return Right(designer);
    } on FirebaseException catch (e) {
      return Left(e.message);
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
}
