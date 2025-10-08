import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/bloc/designer_feedback_bloc_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_feedback_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerFeedbackBloc
    extends Bloc<DesignerFeedbackBlocEvent, DesignerFeedbackBlocState> {
  DesignerFeedbackBloc() : super(const DesignerFeedbackInitial()) {
    on<LoadDesignerFeedback>(_onLoadDesignerFeedback);
    on<LoadDesignerFeedbackCacheFirstThenNetwork>(
      _onLoadDesignerFeedbackCacheFirstThenNetwork,
    );
    on<ClearDesignerFeedback>(
      (event, emit) => emit(const DesignerFeedbackInitial()),
    );
  }

  Future<void> _onLoadDesignerFeedback(
    LoadDesignerFeedback event,
    Emitter<DesignerFeedbackBlocState> emit,
  ) async {
    emit(const DesignerFeedbackLoading());
    final result = await sl<FirebaseDesignersService>().findDesignerFeedback(
      event.refId,
    );

    result.fold((failure) => emit(DesignerFeedbackError(failure.toString())), (
      designCollections,
    ) {
      if (designCollections.isEmpty) {
        emit(const DesignerFeedbackEmpty());
      } else {
        emit(DesignerFeedbacksLoaded(designCollections));
      }
    });
  }

  Future<void> _onLoadDesignerFeedbackCacheFirstThenNetwork(
    LoadDesignerFeedbackCacheFirstThenNetwork event,
    Emitter<DesignerFeedbackBlocState> emit,
  ) async {
    emit(const DesignerFeedbackLoading());
    final result = await sl<FirebaseDesignersService>().findDesignerFeedback(
      event.refId,
    );

    result.fold((failure) => emit(DesignerFeedbackError(failure.toString())), (
      designFeedback,
    ) {
      if (designFeedback.isEmpty) {
        emit(const DesignerFeedbackEmpty());
      } else {
        emit(DesignerFeedbacksLoaded(designFeedback));
      }
    });
  }
}
