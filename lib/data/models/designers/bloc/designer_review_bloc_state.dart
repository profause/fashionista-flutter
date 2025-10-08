import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';

class DesignerReviewBlocState extends Equatable {
  const DesignerReviewBlocState();
  @override
  List<Object?> get props => [];
}

class DesignerReviewInitial extends DesignerReviewBlocState {
  const DesignerReviewInitial();
}

class DesignerReviewLoading extends DesignerReviewBlocState {
  const DesignerReviewLoading();
}

class DesignerReviewLoaded extends DesignerReviewBlocState {
  final DesignerReviewModel reviewModel;
  const DesignerReviewLoaded(this.reviewModel);

  @override
  List<Object?> get props => [reviewModel];
}

class DesignerReviewsLoaded extends DesignerReviewBlocState {
  final List<DesignerReviewModel> reviews;
  final bool fromCache;
  const DesignerReviewsLoaded(this.reviews, {this.fromCache = false});

  @override
  List<Object?> get props => [reviews, fromCache];
}

class DesignerReviewEmpty extends DesignerReviewBlocState {
  const DesignerReviewEmpty();
}

class DesignerReviewError extends DesignerReviewBlocState {
  final String message;
  const DesignerReviewError(this.message);

  @override
  List<Object?> get props => [message];
}
