import 'package:fashionista/data/services/hive/hive_designers_service.dart';
import 'package:fashionista/domain/usecases/designers/find_designers_usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/domain/usecases/designers/find_designer_by_id_usecase.dart';

import 'designer_event.dart';
import 'designer_state.dart';

class DesignerBloc extends Bloc<DesignerBlocEvent, DesignerState> {
  DesignerBloc() : super(const DesignerInitial()) {
    on<LoadDesigner>(_onLoadDesigner);
    on<LoadDesigners>(_onLoadDesigners);
    on<LoadDesignersCacheFirstThenNetwork>(
      _onLoadDesignersCacheFirstThenNetwork,
    );
    on<UpdateDesigner>((event, emit) => emit(DesignerLoaded(event.designer)));
    on<UpdateDesigners>(
      (event, emit) => emit(DesignersLoaded(event.designers)),
    );
    on<ClearDesigner>((event, emit) => emit(const DesignerInitial()));
  }

  Future<void> _onLoadDesigner(
    LoadDesigner event,
    Emitter<DesignerState> emit,
  ) async {
    emit(const DesignerLoading());
    final result = await sl<FindDesignerByIdUsecase>().call(event.uid);

    result.fold(
      (failure) => emit(DesignerError(failure.toString())),
      (designer) => emit(DesignerLoaded(designer)),
    );
  }

  Future<void> _onLoadDesigners(
    LoadDesigners event,
    Emitter<DesignerState> emit,
  ) async {
    emit(const DesignerLoading());

    final cachedItems = await sl<HiveDesignersService>().getItems('designers');
    if (cachedItems.isNotEmpty) {
      emit(DesignersLoaded(cachedItems));
    }

    final result = await sl<FindDesignersUsecase>().call('');

    result.fold(
      (failure) {
        if (cachedItems.isEmpty) {
          // Only emit error if no cache
          emit(DesignerError(failure.toString()));
        }
        // else: keep showing cache quietly
      },
      (designers) async {
        if (designers.isEmpty) {
          if (cachedItems.isEmpty) {
            emit(const DesignerEmpty());
          }
          return;
        }
        // 3️⃣ Compare new data with cache before re-emitting
        final cachedJson = cachedItems.map((e) => e.toJson()).toList().first;
        final freshJson = designers.map((e) => e.toJson()).toList().first;

        if (cachedJson.toString() != freshJson.toString()) {
          // Update cache + emit new state
          //await box.put('collections', designCollections);
          //await box.put('cachedAt', DateTime.now());
          debugPrint('changed');
          emit(DesignersLoaded(designers));
        } else {
          debugPrint('no change');
        }
      },
    );
  }

  
  Future<void> _onLoadDesignersCacheFirstThenNetwork(
    LoadDesignersCacheFirstThenNetwork event,
    Emitter<DesignerState> emit,
  ) async {
    emit(DesignerLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveDesignersService>().getItems('designers');
    if (cachedItems.isNotEmpty) {
      emit(DesignersLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FindDesignersUsecase>().call('');

    await result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(DesignerError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (designers) async {
        if (designers.isEmpty) {
          if (cachedItems.isEmpty) {
            emit(const DesignerEmpty());
          }
          return;
        }

        // 3️⃣ Detect if data has changed
        int? cachedFirstTimestamp = cachedItems.isNotEmpty
            ? cachedItems.first.createdDate?.millisecondsSinceEpoch
            : null;

        int freshFirstTimestamp =
            designers.first.createdDate!.millisecondsSinceEpoch;

        if (cachedFirstTimestamp == null ||
            cachedFirstTimestamp != freshFirstTimestamp) {
          // 4️⃣ Update cache and emit fresh data
          await sl<HiveDesignersService>().insertItems('designers',items: designers);
          emit(DesignersLoaded(designers, fromCache: false));
          emit(DesignersNewData(designers)); // optional "new data" state
          // 🔑 Do NOT call `on<Event>` here again!
        } else {
          // no change
          emit(DesignersLoaded(cachedItems, fromCache: true));
        }
      },
    );
  }
}
