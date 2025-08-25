import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase_user_service.dart';
import 'package:fashionista/domain/repository/profile/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either> fetchUserDetailsFromFirestore(String uid) async {
    return await sl<FirebaseUserService>().fetchUserDetailsFromFirestore(uid);
  }

  @override
  Future<Either> updateUserDetails(User user) async {
    return await sl<FirebaseUserService>().updateUserDetails(user);
  }
  
  @override
  Future<Either> findFavouriteDesignerIds(String uid) async{
    return await sl<FirebaseUserService>().findFavouriteDesignerIds(uid);
  }
}
