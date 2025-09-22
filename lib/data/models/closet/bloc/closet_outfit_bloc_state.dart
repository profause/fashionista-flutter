import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';

class ClosetOutfitBlocState extends Equatable {
  final int itemCount;
  const ClosetOutfitBlocState({this.itemCount = 0});
  @override
  List<Object?> get props => [itemCount];
}

class OutfitInitial extends ClosetOutfitBlocState {
  const OutfitInitial({super.itemCount = 0});
}

class OutfitLoading extends ClosetOutfitBlocState {
  const OutfitLoading({super.itemCount = 0});
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
  const OutfitsLoaded(this.outfits, {this.fromCache = false})
    : super(itemCount: outfits.length);

  @override
  List<Object?> get props => [outfits, itemCount];
}

class OutfitsCounted extends ClosetOutfitBlocState {
  const OutfitsCounted(int itemCount) : super(itemCount: itemCount);

  @override
  List<Object?> get props => [itemCount];
}

class OutfitsEmpty extends ClosetOutfitBlocState {
  const OutfitsEmpty({super.itemCount = 0});
}

class OutfitError extends ClosetOutfitBlocState {
  final String message;
  const OutfitError(this.message, {super.itemCount = 0});

  @override
  List<Object?> get props => [message, itemCount];
}

class OutfitsNewData extends ClosetOutfitBlocState {
  final List<OutfitModel> outfits;
  const OutfitsNewData(this.outfits);

  @override
  List<Object?> get props => [outfits];
}

class OutfitDeleted extends ClosetOutfitBlocState {
  final String message;
  const OutfitDeleted(this.message, {super.itemCount = 0});
  @override
  List<Object?> get props => [message, itemCount];
}
