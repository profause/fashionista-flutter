import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_event.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_state.dart';
import 'package:fashionista/data/services/hive/hive_design_collection_service.dart';
import 'package:fashionista/domain/usecases/design_collection/find_design_collection_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/design_collection/find_design_collections_usecase.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class DesignCollectionBloc
    extends Bloc<DesignCollectionBlocEvent, DesignCollectionState> {
  //DesignCollectionBloc(super.initialState);

  DesignCollectionBloc() : super(const DesignCollectionInitial()) {
    on<LoadDesignCollection>(_onLoadDesignCollection);
    on<LoadDesignCollections>(_onLoadDesignCollections);
    on<UpdateDesignCollection>(
      (event, emit) => emit(DesignCollectionLoaded(event.designCollection)),
    );
    on<LoadDesignCollectionsCacheFirstThenNetwork>(
      _onLoadDesignCollectionsCacheFirstThenNetwork,
    );
    on<ClearDesignCollection>(
      (event, emit) => emit(const DesignCollectionInitial()),
    );
  }
  Future<void> _onLoadDesignCollection(
    LoadDesignCollection event,
    Emitter<DesignCollectionState> emit,
  ) async {
    emit(const DesignCollectionLoading());

    final result = await sl<FindDesignCollectionByIdUsecase>().call(event.uid);

    result.fold(
      (failure) => emit(DesignCollectionError(failure.toString())),
      (designCollection) => emit(DesignCollectionLoaded(designCollection)),
    );
  }

  Future<void> _onLoadDesignCollections(
    LoadDesignCollections event,
    Emitter<DesignCollectionState> emit,
  ) async {
    emit(const DesignCollectionLoading());

    final result = await sl<FindDesignCollectionsUsecase>().call(event.uid);

    result.fold((failure) => emit(DesignCollectionError(failure.toString())), (
      designCollections,
    ) {
      if (designCollections.isEmpty) {
        emit(const DesignCollectionsEmpty());
      } else {
        emit(DesignCollectionsLoaded(designCollections));
      }
    });
  }

  Future<void> _onLoadDesignCollectionsCacheFirstThenNetwork(
    LoadDesignCollectionsCacheFirstThenNetwork event,
    Emitter<DesignCollectionState> emit,
  ) async {
    emit(const DesignCollectionLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveDesignCollectionService>().getItems(
      event.uid,
    );
    if (cachedItems.isNotEmpty) {
      emit(DesignCollectionsLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FindDesignCollectionsUsecase>().call(event.uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(DesignCollectionError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (designCollections) async {
        try {
          if (designCollections.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const DesignCollectionsEmpty());
            }
            return;
          }

          // 3️⃣ Detect if data has changed
          int? cachedFirstTimestamp = cachedItems.isNotEmpty
              ? cachedItems.first.createdAt
              : null;

          int freshFirstTimestamp = designCollections.first.createdAt;

          if (cachedFirstTimestamp == null ||
              cachedFirstTimestamp != freshFirstTimestamp) {
            emit(DesignCollectionsLoaded(designCollections, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveDesignCollectionService>().insertItems(
              event.uid,
              items: designCollections,
            );

            // emit(
            //   DesignCollectionsNewData(designCollections),
            // ); // optional "new data" state
            // 🔑 Do NOT call `on<Event>` here again!
          } else {
            // no change
            emit(DesignCollectionsLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(DesignCollectionError(e.toString()));
        }
      },
    );
  }
}
