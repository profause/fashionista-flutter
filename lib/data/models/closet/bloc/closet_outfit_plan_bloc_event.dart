import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';

abstract class ClosetOutfitPlanBlocEvent extends Equatable {
  const ClosetOutfitPlanBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadOutfitPlan extends ClosetOutfitPlanBlocEvent {
  final String uid;
  const LoadOutfitPlan(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateOutfitPlan extends ClosetOutfitPlanBlocEvent {
  final OutfitPlanModel outfitPlan;
  const UpdateOutfitPlan(this.outfitPlan);

  @override
  List<Object?> get props => [outfitPlan];
}

class LoadOutfitPlans extends ClosetOutfitPlanBlocEvent {
  final String uid;
  const LoadOutfitPlans(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadOutfitPlansCacheFirstThenNetwork extends ClosetOutfitPlanBlocEvent {
  final String uid;
  const LoadOutfitPlansCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteOutfitPlan extends ClosetOutfitPlanBlocEvent {
  final OutfitPlanModel outfitPlanModel;
  const DeleteOutfitPlan(this.outfitPlanModel);

  @override
  List<Object?> get props => [outfitPlanModel];
}

class ClearOutfitPlan extends ClosetOutfitPlanBlocEvent {
  const ClearOutfitPlan();
}
