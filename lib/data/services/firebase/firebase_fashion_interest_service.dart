import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';

abstract class FirebaseFashionInterestService {
  Future<Either<String, Map<String, List<FashionInterestModel>>>>
  fetchFashionInterests();
}

class FirebaseFashionInterestServiceImpl
    implements FirebaseFashionInterestService {
  @override
  Future<Either<String, Map<String, List<FashionInterestModel>>>>
  fetchFashionInterests() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final querySnapshot = await firestore
          .collection('fashion_interests')
          .orderBy('category')
          .get();

      final Map<String, List<FashionInterestModel>> fashionInterests = {};

      for (final doc in querySnapshot.docs) {
        final interest = FashionInterestModel.fromFirestore(doc.data());

        if (interest.category.isEmpty && interest.name.isEmpty) continue;

        fashionInterests.putIfAbsent(interest.category, () => []);
        fashionInterests[interest.category]!.add(interest);
      }

      return Right(fashionInterests);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
