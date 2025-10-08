import 'package:equatable/equatable.dart';

abstract class DesignerReviewBlocEvent extends Equatable {
  const DesignerReviewBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadDesignerReview extends DesignerReviewBlocEvent {
  final String refId;
  const LoadDesignerReview(this.refId);

  @override
  List<Object?> get props => [refId];
}

class LoadDesignerReviewCacheFirstThenNetwork extends DesignerReviewBlocEvent {
  final String refId;
  const LoadDesignerReviewCacheFirstThenNetwork(this.refId);

  @override
  List<Object?> get props => [refId];
}


class ClearDesignerReview extends DesignerReviewBlocEvent {
  const ClearDesignerReview();
}
