import 'package:dartz/dartz.dart';

abstract class UserRepository {
  Future<Either> fetchUserDetailsFromFirestore(String uid);
}