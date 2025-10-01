import 'package:equatable/equatable.dart';

abstract class DesignerFeedbackBlocEvent extends Equatable {
  const DesignerFeedbackBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadDesignerFeedback extends DesignerFeedbackBlocEvent {
  final String refId;
  const LoadDesignerFeedback(this.refId);

  @override
  List<Object?> get props => [refId];
}

class LoadDesignerFeedbackCacheFirstThenNetwork extends DesignerFeedbackBlocEvent {
  final String refId;
  const LoadDesignerFeedbackCacheFirstThenNetwork(this.refId);

  @override
  List<Object?> get props => [refId];
}


class ClearDesignerFeedback extends DesignerFeedbackBlocEvent {
  const ClearDesignerFeedback();
}
