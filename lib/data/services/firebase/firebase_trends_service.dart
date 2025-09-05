import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';

abstract class FirebaseTrendsService {
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

class FirebaseTrendsServiceImpl implements FirebaseTrendsService {
  @override
  Future<Either> addCommentToTrend(CommentModel comment) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('trends')
          .doc(comment.refId)
          .collection('comments')
          .add(comment.toJson());
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
  Future<Either<String, List<TrendFeedModel>>> fetchTrends() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('trends')
          //.where('created_by', isEqualTo: createdBy)
          .orderBy('created_at', descending: true)
          .get();

      //Await all async maps

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

      //await importTrends(sampleTrendsData);
      return Right(trends);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      debugPrint(e.toString());
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
            .collection('likes')
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
      await firestore
          .collection('trends')
          .doc(comment.refId)
          .collection('comments')
          .doc(comment.uid)
          .delete();
      return const Right(
        'successfully deleted comment',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<CommentModel>>> findTrendComments(String trendId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('trends')
          .doc(trendId)
          .collection('comments')
          .orderBy('created_at', descending: true)
          .get();
      // Map each document to a comment
      final designCollection = querySnapshot.docs.map((doc) {
        final d = CommentModel.fromJson(doc.data());
        return d.copyWith(uid: doc.reference.id);
      }).toList();
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> importTrends(List<Map<String, dynamic>> data) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (var item in data) {
      final docRef = firestore.collection('trends').doc(); // auto-ID
      batch.set(docRef, item);
    }

    await batch.commit();
    print('✅ Data imported successfully!');
  }

  List<Map<String, dynamic>> sampleTrendsData = [
    {
      "uid": "trend_001",
      "description":
          "Oversized blazers paired with high-waist trousers are redefining office chic this season.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://placehold.co/180x280.png?text=blazer",
          "type": "image",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Ava Mensah",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#OfficeChic,#BlazerSeason,#Fashionista",
      "number_of_likes": 142,
      "number_of_followers": 37,
      "number_of_comments": 18,
    },
    {
      "uid": "trend_002",
      "description":
          "Eco-friendly fabrics 🌱 are dominating fashion weeks — linen, hemp, and upcycled denim everywhere!",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://placehold.co/180x280.png?text=eco_fabric",
          "type": "image",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Kwame Adjei",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#SustainableFashion,#EcoChic,#UpcycledDenim",
      "number_of_likes": 289,
      "number_of_followers": 91,
      "number_of_comments": 52,
    },
    {
      "uid": "trend_003",
      "description":
          "White sneakers with flowy pastel dresses 👟🌸 — the minimalist summer look everyone’s loving.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://placehold.co/180x280.png?text=sneakers_dress",
          "type": "image",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Sophia Amegashie",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#MinimalistStyle,#SummerVibes, #SneakerTrend",
      "number_of_likes": 430,
      "number_of_followers": 157,
      "number_of_comments": 64,
    },
    {
      "uid": "trend_004",
      "description":
          "Retro sunglasses 🕶️ with bold frames are making waves on Instagram fashion reels.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://www.pexels.com/download/video/4068399/",
          "type": "video",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Daniel Owusu",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#RetroStyle,#BoldFrames,#IGFashion",
      "number_of_likes": 96,
      "number_of_followers": 21,
      "number_of_comments": 7,
    },
    {
      "uid": "trend_005",
      "description":
          "All-black streetwear fits are dominating TikTok 🔥 from hoodies to cargos with chunky boots.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://www.pexels.com/download/video/5082036/",
          "type": "video",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Nana Kofi",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#Streetwear, #AllBlackFit, #TikTokFashion",
      "number_of_likes": 654,
      "number_of_followers": 203,
      "number_of_comments": 80,
    },
    {
      "uid": "trend_006",
      "description":
          "Bright neon crop tops ⚡ are back this summer, paired with oversized jeans for a bold statement.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://www.pexels.com/download/video/6347110/",
          "type": "video",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Linda Boateng",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#NeonVibes,#SummerStyle,#BoldFashion",
      "number_of_likes": 502,
      "number_of_followers": 176,
      "number_of_comments": 41,
    },
    {
      "uid": "trend_007",
      "description":
          "Layered gold chains and hoop earrings ✨ remain a timeless accessory trend.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://www.pexels.com/download/video/7483147/",
          "type": "video",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Esi Konadu",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#JewelryGoals,#GoldChains,#TimelessStyle",
      "number_of_likes": 387,
      "number_of_followers": 98,
      "number_of_comments": 22,
    },
    {
      "uid": "trend_008",
      "description":
          "Plaid skirts and oversized sweaters 🍂 the ultimate fall combo straight from Pinterest boards.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://www.pexels.com/download/video/7250829/",
          "type": "video",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Kylie Addo",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#FallFashion,#PlaidSkirt,#PinterestFit",
      "number_of_likes": 211,
      "number_of_followers": 54,
      "number_of_comments": 12,
    },
    {
      "uid": "trend_009",
      "description":
          "Bucket hats 🎩 are evolving with crochet and patchwork styles for festival season.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://placehold.co/180x280.png?text=bucket_hat",
          "type": "image",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Joey Nartey",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#BucketHat,#FestivalFits,#CrochetStyle",
      "number_of_likes": 178,
      "number_of_followers": 43,
      "number_of_comments": 9,
    },
    {
      "uid": "trend_010",
      "description":
          "Corset tops over shirts 👗 blending vintage with modern streetwear aesthetics.",
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "featured_media": [
        {
          "url": "https://placehold.co/180x280.png?text=corset_trend",
          "type": "video",
        },
      ],
      "created_at": DateTime.now().millisecondsSinceEpoch,
      "updated_at": DateTime.now().millisecondsSinceEpoch,
      "author": {
        "name": "Maya Ofori",
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "tags": "#CorsetTrend,#StreetwearMix,#VintageModern",
      "number_of_likes": 720,
      "number_of_followers": 243,
      "number_of_comments": 95,
    },
  ];
}
