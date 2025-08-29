import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/domain/repository/designers/designers_repository.dart';

class FindDesignersUsecase extends Usecase<Either<String,List<Designer>>, String> {
  @override
  Future<Either<String,List<Designer>>> call(params) {
    return sl<DesignersRepository>().findDesigners();
  }
}
