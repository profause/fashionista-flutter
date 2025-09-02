import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';

abstract class TrendRepository {
  Future<Either> findTrendsCreatedBy(String createdBy);
  Future<Either<String, List<TrendFeedModel>>> fetchTrends();
  Future<Either> addTrendToFirestore(TrendFeedModel trend);
  Future<Either> updateTrendToFirestore(TrendFeedModel trend);
  Future<Either> deleteTrendById(String uid);
  Future<Either> findTrendById(String uid);
  Future<Either> likeOrUnlikeTrend(SocialInteractionModel like);
  Future<Either> followOrUnFollowTrend(SocialInteractionModel follow);
  Future<bool> isFollowedTrend(String uid);
  Future<bool> isLikedTrend(String uid);
  Future<Either> fetchFollowedTrends(List<String> uids);
  Future<Either> addCommentToTrend(CommentModel comment);
  Future<Either> deleteCommentToTrend(CommentModel comment);
  Future<Either> findTrendComments(String uid);
}
