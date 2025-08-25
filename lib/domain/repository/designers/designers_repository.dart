import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';

abstract class DesignersRepository {
  Future<Either> fetchDesigners();
  Future<Either> addDesignerToFirestore(Designer designer);
  Future<Either> updateDesignerToFirestore(Designer designer);
  Future<Either> deleteDesignerById(String uid);
  Future<Either> findDesignerById(String uid);
  Future<Either> addOrRemoveFavouriteDesigner(String designerId);
  Future<bool> isFavouriteDesigner(String designerId);
  Future<Either> fetchFavouriteDesigners(List<String> designerIds);
}
