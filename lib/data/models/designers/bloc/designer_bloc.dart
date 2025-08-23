import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/domain/usecases/designers/find_designer_by_id_usecase.dart';

import 'designer_event.dart';
import 'designer_state.dart';

class DesignerBloc extends HydratedBloc<DesignerBlocEvent, DesignerState> {
  DesignerBloc() : super(const DesignerInitial()) {
    on<LoadDesigner>(_onLoadDesigner);
    on<UpdateDesigner>((event, emit) => emit(DesignerLoaded(event.designer)));
    on<ClearDesigner>((event, emit) => emit(const DesignerInitial()));
  }

  Future<void> _onLoadDesigner(
      LoadDesigner event, Emitter<DesignerState> emit) async {
    emit(const DesignerLoading());
    final result = await sl<FindDesignerByIdUsecase>().call(event.uid);

    result.fold(
      (failure) => emit(DesignerError(failure.toString())),
      (designer) => emit(DesignerLoaded(designer)),
    );
  }

  @override
  DesignerState? fromJson(Map<String, dynamic> json) {
    try {
      return DesignerLoaded(Designer.fromJson(json));
    } catch (_) {
      return const DesignerInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(DesignerState state) {
    if (state is DesignerLoaded) {
      return state.designer.toJson();
    }
    return null;
  }
}
