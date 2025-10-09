import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';

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

class DeleteDesignerReview extends DesignerReviewBlocEvent {
  final DesignerReviewModel designerReviewModel;
  const DeleteDesignerReview(this.designerReviewModel);
  @override
  List<Object?> get props => [designerReviewModel];
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
