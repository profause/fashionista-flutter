import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/profile/user_repository.dart';

class FetchUserProfileUsecase implements Usecase<Either,String>{
  @override
  Future<Either> call(String params) {
    return sl<UserRepository>().fetchUserDetailsFromFirestore(params);
  }
}