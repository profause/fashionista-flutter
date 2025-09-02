import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class IsFollowedTrendUsecase extends Usecase<bool, String> {
  @override
  Future<bool> call(String params) {
    return sl<TrendRepository>().isFollowedTrend(params);
  }
}
