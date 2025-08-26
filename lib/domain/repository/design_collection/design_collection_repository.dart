import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';

abstract class DesignCollectionRepository {
  Future<Either> findDesignCollections(String createdBy);
  Future<Either> fetchDesignCollections();
  Future<Either> addDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  );
  Future<Either> updateDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  );
  Future<Either> deleteDesignCollectionById(String uid);
  Future<Either> findDesignCollectionById(String uid);
  Future<Either> addOrRemoveBookmarkDesign(String uid);
  Future<bool> isBookmarkedDesignCollection(String uid);
  Future<Either> fetchBookmarkedDesignCollections(List<String> uids);
}
