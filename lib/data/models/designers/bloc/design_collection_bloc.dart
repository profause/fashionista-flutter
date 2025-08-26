import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_event.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_state.dart';
import 'package:fashionista/domain/usecases/designers/find_designer_by_id_usecase.dart';
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
    on<ClearDesignCollection>(
      (event, emit) => emit(const DesignCollectionInitial()),
    );
  }
  Future<void> _onLoadDesignCollection(
    LoadDesignCollection event,
    Emitter<DesignCollectionState> emit,
  ) async {
    emit(const DesignCollectionLoading());

    final result = await sl<FindDesignerByIdUsecase>().call(event.uid);

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

    final result = await sl<FindDesignerByIdUsecase>().call(event.uid);

    result.fold(
      (failure) => emit(DesignCollectionError(failure.toString())),
      (designCollections) => emit(DesignCollectionsLoaded(designCollections)),
    );
  }
}
