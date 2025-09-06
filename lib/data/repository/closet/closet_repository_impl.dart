import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/domain/repository/closet/closet_repository.dart';

class ClosetRepositoryImpl extends ClosetRepository {
  @override
  Future<Either> addClosetItem(ClosetItemModel closetItem) {
    return sl<FirebaseClosetService>().addClosetItem(closetItem);
  }

  @override
  Future<Either> addOrRemoveFavouriteClosetItem(String uid) {
    return sl<FirebaseClosetService>().addOrRemoveFavouriteClosetItem(uid);
  }

  @override
  Future<Either> addOrRemoveFavouriteOutfit(String uid) {
    return sl<FirebaseClosetService>().addOrRemoveFavouriteOutfit(uid);
  }

  @override
  Future<Either> addOutfit(OutfitModel outfit) {
    return sl<FirebaseClosetService>().addOutfit(outfit);
  }

  @override
  Future<Either> deleteClosetItem(ClosetItemModel closetItem) {
    return sl<FirebaseClosetService>().deleteClosetItem(closetItem);
  }

  @override
  Future<Either> deleteOutfit(OutfitModel outfit) {
    return sl<FirebaseClosetService>().deleteOutfit(outfit);
  }

  @override
  Future<Either> findClosetItems(String uid) {
    return sl<FirebaseClosetService>().findClosetItems(uid);
  }

  @override
  Future<Either> findOutfits(String uid) {
    return sl<FirebaseClosetService>().findOutfits(uid);
  }

  @override
  Future<Either> updateClosetItem(ClosetItemModel closetItem) {
    return sl<FirebaseClosetService>().updateClosetItem(closetItem);
  }

  @override
  Future<Either> updateOutfit(OutfitModel outfit) {
    return sl<FirebaseClosetService>().updateOutfit(outfit);
  }
}
