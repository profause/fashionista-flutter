import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/designers/designer_service_model.dart';

abstract class FirebaseDesignerServicesService {
  Future<Either<String, List<DesignerServiceModel>>> findDesignerServices(
    String createdBy,
  );
  Future<Either> addDesignerService(DesignerServiceModel designerService);
  Future<Either> updateDesignerService(DesignerServiceModel designerService);
  Future<Either> deleteDesignerService(String uid);
}

class FirebaseDesignerServicesServiceImpl
    implements FirebaseDesignerServicesService {
  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('designer_services');

  @override
  Future<Either<String, List<DesignerServiceModel>>> findDesignerServices(
    String createdBy,
  ) async {
    try {
      if (createdBy.isEmpty) return const Right(<DesignerServiceModel>[]);

      final querySnapshot = await _collection
          .where('created_by', isEqualTo: createdBy)
          .get();

      final services =
          querySnapshot.docs
              .map(
                (doc) => DesignerServiceModel.fromJson(
                  doc.data(),
                ).copyWith(uid: doc.reference.id),
              )
              .toList()
            // Sort by most recently updated first (avoid a composite index).
            ..sort(
              (a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0),
            );

      return Right(services);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> addDesignerService(
    DesignerServiceModel designerService,
  ) async {
    try {
      await _collection
          .doc(designerService.uid)
          .set(designerService.toJson(), SetOptions(merge: true));
      return Right(designerService);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    }
  }

  @override
  Future<Either> updateDesignerService(
    DesignerServiceModel designerService,
  ) async {
    try {
      await _collection
          .doc(designerService.uid)
          .set(designerService.toJson(), SetOptions(merge: true));
      return Right(designerService);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    }
  }

  @override
  Future<Either> deleteDesignerService(String uid) async {
    try {
      await _collection.doc(uid).delete();
      return const Right('successfully deleted designer service');
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
