import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/data/services/firebase_design_collection_service.dart';
import 'package:fashionista/domain/repository/design_collection/design_collection_repository.dart';

class DesignCollectionRepositoryImpl extends DesignCollectionRepository {
  @override
  Future<Either> addDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  ) {
    return sl<FirebaseDesignCollectionService>().addDesignCollectionToFirestore(
      designCollection,
    );
  }

  @override
  Future<Either> addOrRemoveBookmarkDesign(String uid) {
    return sl<FirebaseDesignCollectionService>().addOrRemoveBookmarkDesign(uid);
  }

  @override
  Future<Either> deleteDesignCollectionById(String uid) {
    return sl<FirebaseDesignCollectionService>().deleteDesignCollectionById(
      uid,
    );
  }

  @override
  Future<Either> fetchBookmarkedDesignCollections(List<String> uids) {
    return sl<FirebaseDesignCollectionService>()
        .fetchBookmarkedDesignCollections(uids);
  }

  @override
  Future<Either> fetchDesignCollections() {
    return sl<FirebaseDesignCollectionService>().fetchDesignCollections();
  }

  @override
  Future<Either> findDesignCollectionById(String uid) {
    return sl<FirebaseDesignCollectionService>().findDesignCollectionById(uid);
  }

  @override
  Future<Either> findDesignCollections(String createdBy) {
    return sl<FirebaseDesignCollectionService>().findDesignCollections(
      createdBy,
    );
  }

  @override
  Future<bool> isBookmarkedDesignCollection(String uid) {
    return sl<FirebaseDesignCollectionService>().isBookmarkedDesignCollection(
      uid,
    );
  }

  @override
  Future<Either> updateDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  ) {
    return sl<FirebaseDesignCollectionService>()
        .updateDesignCollectionToFirestore(designCollection);
  }
}
