import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/design_collection/design_collection_repository.dart';

class FindDesignCollectionsUsecase extends Usecase<Either, String> {
  @override
  Future<Either> call(String params) {
    return sl<DesignCollectionRepository>().findDesignCollections(params);
  }
}
