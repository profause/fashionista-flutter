import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';

class ClosetOutfitPlanBlocState extends Equatable {
  const ClosetOutfitPlanBlocState();
  @override
  List<Object?> get props => [];
}

class OutfitPlanInitial extends ClosetOutfitPlanBlocState {
  const OutfitPlanInitial();
}

class OutfitPlanLoading extends ClosetOutfitPlanBlocState {
  const OutfitPlanLoading();
}

class OutfitPlanLoaded extends ClosetOutfitPlanBlocState {
  final OutfitPlanModel outfit;
  const OutfitPlanLoaded(this.outfit);

  @override
  List<Object?> get props => [outfit];
}

class OutfitPlanUpdated extends ClosetOutfitPlanBlocState {
  final OutfitPlanModel outfitPlan;
  const OutfitPlanUpdated(this.outfitPlan);
  @override
  List<Object?> get props => [outfitPlan];
}

class OutfitPlansLoaded extends ClosetOutfitPlanBlocState {
  final List<OutfitPlanModel> outfitPlans;
  final bool fromCache;
  const OutfitPlansLoaded(this.outfitPlans, {this.fromCache = false});

  @override
  List<Object?> get props => [outfitPlans];
}

class OutfitPlansCalendarLoaded extends ClosetOutfitPlanBlocState {
  final Map<DateTime, List<OutfitPlanModel>> outfitPlans;
  final bool fromCache;
  const OutfitPlansCalendarLoaded(this.outfitPlans, {this.fromCache = false});

  @override
  List<Object?> get props => [outfitPlans];
}

class OutfitPlansEmpty extends ClosetOutfitPlanBlocState {
  const OutfitPlansEmpty();
}

class OutfitPlanError extends ClosetOutfitPlanBlocState {
  final String message;
  const OutfitPlanError(this.message);

  @override
  List<Object?> get props => [message];
}

class OutfitPlansNewData extends ClosetOutfitPlanBlocState {
  final List<OutfitPlanModel> outfits;
  const OutfitPlansNewData(this.outfits);

  @override
  List<Object?> get props => [outfits];
}

class OutfitPlanDeleted extends ClosetOutfitPlanBlocState {
  final String message;
  const OutfitPlanDeleted(this.message);
  @override
  List<Object?> get props => [message];
}
