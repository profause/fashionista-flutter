import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';

abstract class ClosetOutfitBlocEvent extends Equatable {
  const ClosetOutfitBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadOutfit extends ClosetOutfitBlocEvent {
  final String uid;
  const LoadOutfit(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateOutfit extends ClosetOutfitBlocEvent {
  final OutfitModel outfit;
  const UpdateOutfit(this.outfit);

  @override
  List<Object?> get props => [outfit];
}

class LoadOutfits extends ClosetOutfitBlocEvent {
  final String uid;
  const LoadOutfits(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadOutfitsCacheFirstThenNetwork extends ClosetOutfitBlocEvent {
  final String uid;
  const LoadOutfitsCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}


class OutfitCounter extends ClosetOutfitBlocEvent {
  final String uid;
  const OutfitCounter(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteOutfit extends ClosetOutfitBlocEvent {
  final OutfitModel outfitModel;
  const DeleteOutfit(this.outfitModel);

  @override
  List<Object?> get props => [outfitModel];
}

class ClearOutfit extends ClosetOutfitBlocEvent {
  const ClearOutfit();
}
