import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class IsLikedTrendUsecase extends Usecase<bool, String> {
  @override
  Future<bool> call(String params) {
    return sl<TrendRepository>().isLikedTrend(params);
  }
}
