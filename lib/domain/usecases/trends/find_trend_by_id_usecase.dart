import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class FindTrendByIdUsecase implements Usecase<Either, String> {
  @override
  Future<Either> call(params) {
    return sl<TrendRepository>().findTrendById(params);
  }
}
