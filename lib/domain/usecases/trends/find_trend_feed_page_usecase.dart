import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/trends/trend_feed_page.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class FindTrendFeedPageParams {
  final int limit;
  final Object? cursor;

  const FindTrendFeedPageParams({this.limit = 20, this.cursor});
}

class FindTrendFeedPageUsecase
    extends Usecase<Either<String, TrendFeedPage>, FindTrendFeedPageParams> {
  @override
  Future<Either<String, TrendFeedPage>> call(FindTrendFeedPageParams params) {
    return sl<TrendRepository>().fetchTrendsPage(
      limit: params.limit,
      cursor: params.cursor,
    );
  }
}
