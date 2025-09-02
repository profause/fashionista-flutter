import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class FindTrendsUsecase
    extends Usecase<Either<String, List<TrendFeedModel>>, String> {
  @override
  Future<Either<String, List<TrendFeedModel>>> call(String params) {
    return sl<TrendRepository>().fetchTrends();
  }
}
