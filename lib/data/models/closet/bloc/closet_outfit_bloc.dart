import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/data/services/hive/hive_outfit_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClosetOutfitBloc
    extends Bloc<ClosetOutfitBlocEvent, ClosetOutfitBlocState> {
  ClosetOutfitBloc() : super(const OutfitInitial()) {
    on<LoadOutfits>(_onLoadOutfits);
    on<UpdateOutfit>(_updateOutfit);
    on<DeleteOutfit>(_deleteOutfit);
    on<LoadOutfitsCacheFirstThenNetwork>(_onLoadOutfitsCacheFirstThenNetwork);
    on<ClearOutfit>((event, emit) => emit(const OutfitInitial()));
  }

  Future<void> _onLoadOutfits(
    LoadOutfits event,
    Emitter<ClosetOutfitBlocState> emit,
  ) async {
    emit(const OutfitLoading());

    final result = await sl<FirebaseClosetService>().findOutfits(event.uid);

    result.fold(
      (failure) => emit(OutfitError(failure.toString())),
      (outfit) => emit(OutfitsLoaded(outfit)),
    );
  }

  Future<void> _deleteOutfit(
    DeleteOutfit event,
    Emitter<ClosetOutfitBlocState> emit,
  ) async {
    var result = await sl<FirebaseClosetService>().deleteOutfit(
      event.outfitModel,
    );
    result.fold((l) => null, (r) => emit(OutfitDeleted(r)));
  }

  Future<void> _updateOutfit(
    UpdateOutfit event,
    Emitter<ClosetOutfitBlocState> emit,
  ) async {
    emit(OutfitLoading());
    emit(OutfitUpdated(event.outfit));
    //emit(OutfitLoaded(event.outfit));
  }

  Future<void> _onLoadOutfitsCacheFirstThenNetwork(
    LoadOutfitsCacheFirstThenNetwork event,
    Emitter<ClosetOutfitBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }

    emit(const OutfitLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveOutfitService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(OutfitsLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FirebaseClosetService>().findOutfits(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(OutfitError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (closetitems) async {
        try {
          if (closetitems.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const OutfitsEmpty());
            }
            return;
          }

          if (cachedItems.toString() != closetitems.toString()) {
            emit(OutfitsLoaded(closetitems, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveOutfitService>().insertItems(
              'closet_items',
              items: closetitems,
            );
          } else {
            // no change
            emit(OutfitsLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(OutfitError(e.toString()));
        }
      },
    );
  }
}
