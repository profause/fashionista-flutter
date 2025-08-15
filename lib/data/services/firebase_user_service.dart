import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/profile/models/user.dart';

abstract class FirebaseUserService {
  Future<Either> fetchUserDetailsFromFirestore(String uid);
}

class FirebaseUserServiceImpl implements FirebaseUserService {
  @override
  Future<Either> fetchUserDetailsFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('users').doc(uid);
      DocumentSnapshot doc = await docRef.get();
      User user = User.fromJson(doc.data() as Map<String, dynamic>);
      return Right(user);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }
}
