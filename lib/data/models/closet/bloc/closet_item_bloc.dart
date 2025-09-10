import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/data/services/hive/hive_closet_item_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClosetItemBloc extends Bloc<ClosetItemBlocEvent, ClosetItemBlocState> {
  ClosetItemBloc() : super(const ClosetItemInitial()) {
    on<LoadClosetItems>(_onLoadClosetItems);
    on<UpdateClosetItem>(_updateClosetItem);
    on<DeleteClosetItem>(_deleteClosetItem);
    on<LoadClosetItemsCacheFirstThenNetwork>(
      _onLoadClosetItemsCacheFirstThenNetwork,
    );
    on<ClearClosetItem>((event, emit) => emit(const ClosetItemInitial()));
  }

  Future<void> _onLoadClosetItems(
    LoadClosetItems event,
    Emitter<ClosetItemBlocState> emit,
  ) async {
    emit(const ClosetItemLoading());

    final result = await sl<FirebaseClosetService>().findClosetItems(event.uid);

    result.fold(
      (failure) => emit(ClosetItemError(failure.toString())),
      (closetitem) => emit(ClosetItemsLoaded(closetitem)),
    );
  }

  Future<void> _deleteClosetItem(
    DeleteClosetItem event,
    Emitter<ClosetItemBlocState> emit,
  ) async {
    // var result = await sl<FirebaseClosetService>().deleteClosetItem(
    //   event.closetItemModel,
    // );
    // result.fold((l) => null, (r) => emit(ClosetItemDeleted(r)));

    final cachedItems = await sl<HiveClosetItemService>().getItems(
      event.closetItemModel.createdBy!,
    );
    // ✅ find index by matching uid
    final index = cachedItems.indexWhere(
      (item) => item.uid == event.closetItemModel.uid,
    );

    if (index != -1) {
      cachedItems.removeAt(index);

      try {
        // ✅ persist updated list back to Hive
        await sl<HiveClosetItemService>().insertItems('', items: cachedItems);

        if (cachedItems.isEmpty) {
          emit(const ClosetItemsEmpty());
          return;
        }

        emit(ClosetItemsLoaded(cachedItems, fromCache: true));
      } catch (e) {
        // ❌ Rollback if persistence failed (optional)
        emit(ClosetItemError("Failed to delete item: $e"));
      }
    }
  }

  Future<void> _updateClosetItem(
    UpdateClosetItem event,
    Emitter<ClosetItemBlocState> emit,
  ) async {
    emit(ClosetItemLoading());
    emit(ClosetItemUpdated(event.closetitem));
    //emit(ClosetItemLoaded(event.closetitem));
  }

  Future<void> _onLoadClosetItemsCacheFirstThenNetwork(
    LoadClosetItemsCacheFirstThenNetwork event,
    Emitter<ClosetItemBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }

    emit(const ClosetItemLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveClosetItemService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(ClosetItemsLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FirebaseClosetService>().findClosetItems(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(ClosetItemError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (closetitems) async {
        try {
          if (closetitems.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const ClosetItemsEmpty());
            }
            emit(const ClosetItemsEmpty());
            return;
          }

          if (cachedItems.toString() != closetitems.toString()) {
            emit(ClosetItemsLoaded(closetitems, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveClosetItemService>().insertItems(
              'closet_items',
              items: closetitems,
            );
          } else {
            // no change
            emit(ClosetItemsLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(ClosetItemError(e.toString()));
        }
      },
    );
  }
}
