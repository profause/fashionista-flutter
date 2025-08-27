import 'package:fashionista/domain/usecases/designers/find_designers_usecase.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/domain/usecases/designers/find_designer_by_id_usecase.dart';

import 'designer_event.dart';
import 'designer_state.dart';

class DesignerBloc extends Bloc<DesignerBlocEvent, DesignerState> {
  DesignerBloc() : super(const DesignerInitial()) {
    on<LoadDesigner>(_onLoadDesigner);
    on<LoadDesigners>(_onLoadDesigners);
    on<UpdateDesigner>((event, emit) => emit(DesignerLoaded(event.designer)));
    on<UpdateDesigners>((event, emit) => emit(DesignersLoaded(event.designers)));
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

    final result = await sl<FindDesignersUsecase>().call('');

    result.fold((failure) => emit(DesignerError(failure.toString())), (
      designers,
    ) {
      if (designers.isEmpty) {
        emit(const DesignerEmpty());
      } else {
        emit(DesignersLoaded(designers));
      }
    });
  }
}
