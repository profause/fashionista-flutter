
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/repository/trends/trend_repository.dart';

class TrendRepositoryImpl extends TrendRepository {
  @override
  Future<Either> addCommentToTrend(CommentModel comment) {
    // TODO: implement addCommentToTrend
    throw UnimplementedError();
  }

  @override
  Future<Either> addTrendToFirestore(TrendFeedModel trend) {
    // TODO: implement addTrendToFirestore
    throw UnimplementedError();
  }

  @override
  Future<Either> deleteTrendById(String uid) {
    // TODO: implement deleteTrendById
    throw UnimplementedError();
  }

  @override
  Future<Either> fetchFollowedTrends(List<String> uids) {
    // TODO: implement fetchFollowedTrends
    throw UnimplementedError();
  }

  @override
  Future<Either> fetchTrends() {
    // TODO: implement fetchTrends
    throw UnimplementedError();
  }

  @override
  Future<Either> findTrendById(String uid) {
    // TODO: implement findTrendById
    throw UnimplementedError();
  }

  @override
  Future<Either> findTrends(String createdBy) {
    // TODO: implement findTrends
    throw UnimplementedError();
  }

  @override
  Future<Either> followOrUnFollowTrend(SocialInteractionModel follow) {
    // TODO: implement followOrUnFollowTrend
    throw UnimplementedError();
  }

  @override
  Future<bool> isFollowedTrend(String uid) {
    // TODO: implement isFollowedTrend
    throw UnimplementedError();
  }

  @override
  Future<bool> isLikedTrend(String uid) {
    // TODO: implement isLikedTrend
    throw UnimplementedError();
  }

  @override
  Future<Either> likeOrUnlikeTrend(SocialInteractionModel like) {
    // TODO: implement likeOrUnlikeTrend
    throw UnimplementedError();
  }

  @override
  Future<Either> updateTrendToFirestore(TrendFeedModel trend) {
    // TODO: implement updateTrendToFirestore
    throw UnimplementedError();
  }

}