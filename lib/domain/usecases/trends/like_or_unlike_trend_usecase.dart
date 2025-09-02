import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class LikeOrUnlikeTrendUsecase extends Usecase<Either,SocialInteractionModel>{
  @override
  Future<Either> call(SocialInteractionModel params) {
    return sl<TrendRepository>().likeOrUnlikeTrend(params);
  }

}