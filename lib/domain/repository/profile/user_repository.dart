import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/profile/models/user.dart';

abstract class UserRepository {
  Future<Either<String, User>> fetchUserDetailsFromFirestore(String uid);
  Future<Either> updateUserDetails(User user);
  Future<Either> findFavouriteDesignerIds();
  Future<Either> findBookmarkedDesignCollectionIds();
  Future<bool> hasBookmarkedDesignCollection();
}