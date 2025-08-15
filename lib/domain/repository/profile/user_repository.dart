import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/profile/models/user.dart';

abstract class UserRepository {
  Future<Either> fetchUserDetailsFromFirestore(String uid);
  Future<Either> updateUserDetails(User user);
}