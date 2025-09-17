import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

abstract class FirebaseFashionInterestService {
  Future<Either<String, Map<String, List<String>>>> fetchFashionInterests();
}

class FirebaseFashionInterestServiceImpl
    implements FirebaseFashionInterestService {
  @override
  Future<Either<String, Map<String, List<String>>>>
  fetchFashionInterests() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final querySnapshot = await firestore
          .collection('fashion_interests')
          .get();

      final Map<String, List<String>> fashionInterests = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        final name = data['name'] as String?;

        if (category != null && name != null) {
          fashionInterests.putIfAbsent(category, () => []);
          fashionInterests[category]!.add(name);
        }
      }

      return Right(fashionInterests);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
