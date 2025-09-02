import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class AddTrendUsecase extends Usecase<Either,TrendFeedModel>{
  @override
  Future<Either> call(TrendFeedModel params) {
    return sl<TrendRepository>().addTrendToFirestore(params);
  }
}