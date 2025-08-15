import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/domain/repository/profile/user_repository.dart';

class UpdateUserProfileUsecase implements Usecase<Either,User>{
  @override
  Future<Either> call(User params) {
    return sl<UserRepository>().updateUserDetails(params);
  }
}