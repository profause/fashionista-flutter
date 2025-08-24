import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/designers/designers_repository.dart';

class AddOrRemoveFavouriteUsecase implements Usecase<Either, String> {
  @override
  Future<Either> call(String params) {
    return sl<DesignersRepository>().addOrRemoveFavouriteDesigner(params);
  }
}
