import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/designers/designers_repository.dart';

class FindFavouriteDesignersUsecase extends Usecase<Either,List<String>>{
  @override
  Future<Either> call(List<String> params) {
    return sl<DesignersRepository>().fetchFavouriteDesigners(params);
  }

}