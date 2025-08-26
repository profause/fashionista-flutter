import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/domain/repository/design_collection/design_collection_repository.dart';

class AddDesignCollectionUsecase extends Usecase<Either,DesignCollectionModel>{
  @override
  Future<Either> call(DesignCollectionModel params) {
    return sl<DesignCollectionRepository>().addDesignCollectionToFirestore(params);
  }
  
}