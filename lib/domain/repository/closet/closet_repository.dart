import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';

abstract class ClosetRepository {
  Future<Either> addClosetItem(ClosetItemModel closetItem);
  Future<Either> updateClosetItem(ClosetItemModel closetItem);
  Future<Either> deleteClosetItem(ClosetItemModel closetItem);
  Future<Either> findClosetItems(String uid);
  Future<Either> addOrRemoveFavouriteClosetItem(String uid);

  Future<Either> addOutfit(OutfitModel outfit);
  Future<Either> updateOutfit(OutfitModel outfit);
  Future<Either> deleteOutfit(OutfitModel outfit);
  Future<Either> findOutfits(String uid);
  Future<Either> addOrRemoveFavouriteOutfit(String uid);
}
