import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class DeleteTrendCommentUsecase extends Usecase<Either, CommentModel> {
  @override
  Future<Either> call(CommentModel params) {
    return sl<TrendRepository>().deleteCommentToTrend(params);
  }
}
