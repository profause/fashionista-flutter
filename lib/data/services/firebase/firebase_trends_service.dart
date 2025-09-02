import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseTrendsService {
  Future<Either> findTrendsCreatedBy(String createdBy);
  Future<Either> fetchTrends();
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

class FirebaseTrendsServiceImpl implements FirebaseTrendsService {
  @override
  Future<Either> addCommentToTrend(CommentModel comment) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('trend_comments')
          .doc(comment.uid)
          .set(comment.toJson(), SetOptions(merge: true));
      return Right(comment);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> addTrendToFirestore(TrendFeedModel trend) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('trends')
          .doc(trend.uid)
          .set(trend.toJson(), SetOptions(merge: true));
      return Right(trend);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteTrendById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore.collection('trends').doc(uid).delete();
      return const Right('successfully deleted post'); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> fetchFollowedTrends(List<String> uids) {
    // TODO: implement fetchFollowedTrends
    throw UnimplementedError();
  }

  @override
  Future<Either> fetchTrends() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('trends')
          //.where('created_by', isEqualTo: createdBy)
          .orderBy('created_at', descending: true)
          .get();

      // Await all async maps
      final trends = await Future.wait(
        querySnapshot.docs.map((doc) async {
          bool isLiked = await isLikedTrend(doc.reference.id);
          bool isFollowed = await isFollowedTrend(doc.reference.id);
          final d = TrendFeedModel.fromJson(doc.data());
          return d.copyWith(
            uid: doc.reference.id,
            isLiked: isLiked,
            isFollowed: isFollowed,
          );
        }),
      );

      return Right(trends);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> findTrendById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('trends').doc(uid);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('Design post not found');
      }

      TrendFeedModel trendFeedModel = TrendFeedModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      return Right(trendFeedModel);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> findTrendsCreatedBy(String createdBy) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('trends')
          .where('created_by', isEqualTo: createdBy)
          .orderBy('created_at', descending: true)
          .get();

      // Await all async maps
      final trends = await Future.wait(
        querySnapshot.docs.map((doc) async {
          bool isLiked = await isLikedTrend(doc.reference.id);
          bool isFollowed = await isFollowedTrend(doc.reference.id);
          final d = TrendFeedModel.fromJson(doc.data());
          return d.copyWith(
            uid: doc.reference.id,
            isLiked: isLiked,
            isFollowed: isFollowed,
          );
        }),
      );

      return Right(trends);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> followOrUnFollowTrend(SocialInteractionModel follow) async {
    try {
      final us = FirebaseAuth.instance.currentUser;
      if (us == null) {
        return Left('User is not logged in');
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isFollowed;
      QuerySnapshot querySnapshot = await firestore
          .collection('trends')
          .doc(follow.refId)
          .collection('followers')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await firestore
            .collection('trends')
            .doc(follow.refId)
            .collection('followers')
            .doc(uid)
            .set(
              follow
                  .copyWith(
                    uid: uid,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  )
                  .toJson(),
              SetOptions(merge: true),
            );
        isFollowed = true;
      } else {
        await querySnapshot.docs.first.reference.delete();
        isFollowed = false;
      }
      return Right(isFollowed);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<bool> isFollowedTrend(String refId) async {
    try {
      final us = FirebaseAuth.instance.currentUser;
      if (us == null) {
        return false;
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isBookmarked;
      QuerySnapshot querySnapshot = await firestore
          .collection('trends')
          .doc(refId)
          .collection('followers')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isBookmarked = false;
      } else {
        isBookmarked = true;
      }
      return isBookmarked;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isLikedTrend(String refId) async {
    try {
      final us = FirebaseAuth.instance.currentUser;
      if (us == null) {
        return false;
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isLikedTrend;
      QuerySnapshot querySnapshot = await firestore
          .collection('trends')
          .doc(refId)
          .collection('likes')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isLikedTrend = false;
      } else {
        isLikedTrend = true;
      }
      return isLikedTrend;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either> likeOrUnlikeTrend(SocialInteractionModel like) async {
    try {
      final us = FirebaseAuth.instance.currentUser;
      if (us == null) {
        return Left('User is not logged in');
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isLiked;
      QuerySnapshot querySnapshot = await firestore
          .collection('trends')
          .doc(like.refId)
          .collection('likes')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await firestore
            .collection('trends')
            .doc(like.refId)
            .collection('followers')
            .doc(uid)
            .set(
              like
                  .copyWith(
                    uid: uid,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  )
                  .toJson(),
              SetOptions(merge: true),
            );
        isLiked = true;
      } else {
        await querySnapshot.docs.first.reference.delete();
        isLiked = false;
      }
      return Right(isLiked);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateTrendToFirestore(TrendFeedModel trend) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('trends')
          .doc(trend.uid)
          .set(trend.toJson(), SetOptions(merge: true));
      return Right(trend);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteCommentToTrend(CommentModel comment) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete the document with the given uid
      await firestore.collection('trend_comments').doc(comment.uid).delete();
      return const Right(
        'successfully deleted design collection',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> findTrendComments(String trendId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('trend_comments')
          .where('ref_id', isEqualTo: trendId)
          .orderBy('created_at', descending: true)
          .get();
      // Map each document to a DesignCollection
      final designCollection = querySnapshot.docs.map((doc) {
        final d = CommentModel.fromJson(doc.data());
        return d;
      }).toList();
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
