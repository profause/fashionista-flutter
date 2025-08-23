import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/domain/repository/designers/designers_repository.dart';

class AddDesignerUsecase extends Usecase<Either, Designer> {
  @override
  Future<Either> call(Designer params) {
    return sl<DesignersRepository>().addDesignerToFirestore(params);
  }
}
