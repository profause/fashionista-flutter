import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';

class ClosetOutfitBlocState extends Equatable {
  const ClosetOutfitBlocState();
  @override
  List<Object?> get props => [];
}

class OutfitInitial extends ClosetOutfitBlocState {
  const OutfitInitial();
}

class OutfitLoading extends ClosetOutfitBlocState {
  const OutfitLoading();
}

class OutfitLoaded extends ClosetOutfitBlocState {
  final OutfitModel outfit;
  const OutfitLoaded(this.outfit);

  @override
  List<Object?> get props => [outfit];
}

class OutfitUpdated extends ClosetOutfitBlocState {
  final OutfitModel outfit;
  const OutfitUpdated(this.outfit);
  @override
  List<Object?> get props => [outfit];
}

class OutfitsLoaded extends ClosetOutfitBlocState {
  final List<OutfitModel> outfits;
  final bool fromCache;
  const OutfitsLoaded(this.outfits, {this.fromCache = false});

  @override
  List<Object?> get props => [outfits];
}

class OutfitsEmpty extends ClosetOutfitBlocState {
  const OutfitsEmpty();
}

class OutfitError extends ClosetOutfitBlocState {
  final String message;
  const OutfitError(this.message);

  @override
  List<Object?> get props => [message];
}

class OutfitsNewData extends ClosetOutfitBlocState {
  final List<OutfitModel> outfits;
  const OutfitsNewData(this.outfits);

  @override
  List<Object?> get props => [outfits];
}

class OutfitDeleted extends ClosetOutfitBlocState {
  final String message;
  const OutfitDeleted(this.message);
  @override
  List<Object?> get props => [message];
}
