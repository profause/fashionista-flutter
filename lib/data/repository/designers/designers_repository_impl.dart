import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/services/firebase_designers_service.dart';
import 'package:fashionista/domain/repository/designers/designers_repository.dart';

class DesignersRepositoryImpl extends DesignersRepository {
  @override
  Future<Either> addDesignerToFirestore(Designer designer) {
    return sl<FirebaseDesignersService>().addDesignerToFirestore(designer);
  }

  @override
  Future<Either> deleteDesignerById(String clientId) {
    return sl<FirebaseDesignersService>().deleteDesignerById(clientId);
  }

  @override
  Future<Either> fetchDesigners() {
    return sl<FirebaseDesignersService>().fetchDesigners();
  }

  @override
  Future<Either> findDesignerById(String clientId) {
    return sl<FirebaseDesignersService>().findDesignerById(clientId);
  }

  @override
  Future<Either> updateDesignerToFirestore(Designer designer) {
    return sl<FirebaseDesignersService>().updateDesignerToFirestore(designer);
  }

  @override
  Future<Either> addOrRemoveFavouriteDesigner(String designerId) {
    return sl<FirebaseDesignersService>().addOrRemoveFavouriteDesigner(
      designerId,
    );
  }

  @override
  Future<bool> isFavouriteDesigner(designerId) {
    return sl<FirebaseDesignersService>().isFavouriteDesigner(designerId);
  }
}
