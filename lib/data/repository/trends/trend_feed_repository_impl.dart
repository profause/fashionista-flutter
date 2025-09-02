
import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class TrendRepositoryImpl extends TrendRepository {
  @override
  Future<Either> addCommentToTrend(CommentModel comment) {
    return sl<FirebaseTrendsService>().addCommentToTrend(comment);
  }

  @override
  Future<Either> addTrendToFirestore(TrendFeedModel trend) {
    return sl<FirebaseTrendsService>().addTrendToFirestore(trend);
  }

  @override
  Future<Either> deleteTrendById(String uid) {
    return sl<FirebaseTrendsService>().deleteTrendById(uid);
  }

  @override
  Future<Either> fetchFollowedTrends(List<String> uids) {
    return sl<FirebaseTrendsService>().fetchFollowedTrends(uids);
  }

  @override
  Future<Either> fetchTrends() {
    return sl<FirebaseTrendsService>().fetchTrends();
  }

  @override
  Future<Either> findTrendById(String uid) {
    return sl<FirebaseTrendsService>().findTrendById(uid);
  }

  @override
  Future<Either> findTrendsCreatedBy(String createdBy) {
    return sl<FirebaseTrendsService>().findTrendsCreatedBy(createdBy);
  }

  @override
  Future<Either> followOrUnFollowTrend(SocialInteractionModel follow) {
    return sl<FirebaseTrendsService>().followOrUnFollowTrend(follow);
  }

  @override
  Future<bool> isFollowedTrend(String uid) {
    return sl<FirebaseTrendsService>().isFollowedTrend(uid);
  }

  @override
  Future<bool> isLikedTrend(String uid) {
    return sl<FirebaseTrendsService>().isLikedTrend(uid);
  }

  @override
  Future<Either> likeOrUnlikeTrend(SocialInteractionModel like) {
    return sl<FirebaseTrendsService>().likeOrUnlikeTrend(like);
  }

  @override
  Future<Either> updateTrendToFirestore(TrendFeedModel trend) {
    return sl<FirebaseTrendsService>().updateTrendToFirestore(trend);
  }
  
  @override
  Future<Either> deleteCommentToTrend(CommentModel comment) {
    return sl<FirebaseTrendsService>().deleteCommentToTrend(comment);
  }
  
  @override
  Future<Either> findTrendComments(String uid) {
    return sl<FirebaseTrendsService>().findTrendComments(uid);
  }

}