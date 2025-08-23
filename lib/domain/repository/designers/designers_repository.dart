import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';

abstract class DesignersRepository {
  Future<Either> fetchDesigners();
  Future<Either> addDesignerToFirestore(Designer designer);
  Future<Either> updateDesignerToFirestore(Designer designer);
  Future<Either> deleteDesignerById(String clientId);
  Future<Either> findDesignerById(String clientId);
}