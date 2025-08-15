import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/auth/auth_repository.dart';

class SignOutUsecase implements Usecase<void,String>{
  @override
  Future<void> call(String params) {
    return sl<AuthRepository>().signOut();
  }
}