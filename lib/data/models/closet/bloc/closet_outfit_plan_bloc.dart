import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/data/services/hive/hive_outfit_plan_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClosetOutfitPlanPlanPlanBloc
    extends Bloc<ClosetOutfitPlanBlocEvent, ClosetOutfitPlanBlocState> {
  ClosetOutfitPlanPlanPlanBloc() : super(const OutfitPlanInitial()) {
    on<LoadOutfitPlans>(_onLoadOutfitPlans);
    on<UpdateOutfitPlan>(_updateOutfitPlan);
    on<DeleteOutfitPlan>(_deleteOutfitPlan);
    on<LoadOutfitPlansCacheFirstThenNetwork>(
      _onLoadOutfitPlansCacheFirstThenNetwork,
    );
    on<ClearOutfitPlan>((event, emit) => emit(const OutfitPlanInitial()));
  }

  Future<void> _onLoadOutfitPlans(
    LoadOutfitPlans event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    emit(const OutfitPlanLoading());

    final result = await sl<FirebaseClosetService>().findOutfitPlans(event.uid);

    result.fold(
      (failure) => emit(OutfitPlanError(failure.toString())),
      (outfit) => emit(OutfitPlansLoaded(outfit)),
    );
  }

  Future<void> _deleteOutfitPlan(
    DeleteOutfitPlan event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    var result = await sl<FirebaseClosetService>().deleteOutfitPlan(
      event.outfitPlanModel,
    );
    result.fold((l) => null, (r) => emit(OutfitPlanDeleted(r)));
  }

  Future<void> _updateOutfitPlan(
    UpdateOutfitPlan event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    emit(OutfitPlanLoading());
    emit(OutfitPlanUpdated(event.outfitPlan));
    //emit(OutfitPlanLoaded(event.outfit));
  }

  Future<void> _onLoadOutfitPlansCacheFirstThenNetwork(
    LoadOutfitPlansCacheFirstThenNetwork event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }

    emit(const OutfitPlanLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveOutfitPlanService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(OutfitPlansLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FirebaseClosetService>().findOutfitPlans(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(OutfitPlanError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (closetitems) async {
        try {
          if (closetitems.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const OutfitPlansEmpty());
            }
            return;
          }

          if (cachedItems.toString() != closetitems.toString()) {
            emit(OutfitPlansLoaded(closetitems, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveOutfitPlanService>().insertItems(
              'closet_items',
              items: closetitems,
            );
          } else {
            // no change
            emit(OutfitPlansLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(OutfitPlanError(e.toString()));
        }
      },
    );
  }
}
