import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';

class DesignerFeedbackBlocState extends Equatable {
  const DesignerFeedbackBlocState();
  @override
  List<Object?> get props => [];
}

class DesignerFeedbackInitial extends DesignerFeedbackBlocState {
  const DesignerFeedbackInitial();
}

class DesignerFeedbackLoading extends DesignerFeedbackBlocState {
  const DesignerFeedbackLoading();
}

class DesignerFeedbackLoaded extends DesignerFeedbackBlocState {
  final CommentModel comment;
  const DesignerFeedbackLoaded(this.comment);

  @override
  List<Object?> get props => [comment];
}

class DesignerFeedbacksLoaded extends DesignerFeedbackBlocState {
  final List<CommentModel> comments;
  final bool fromCache;
  const DesignerFeedbacksLoaded(this.comments, {this.fromCache = false});

  @override
  List<Object?> get props => [comments];
}

class DesignerFeedbackEmpty extends DesignerFeedbackBlocState {
  const DesignerFeedbackEmpty();
}

class DesignerFeedbackError extends DesignerFeedbackBlocState {
  final String message;
  const DesignerFeedbackError(this.message);

  @override
  List<Object?> get props => [message];
}
