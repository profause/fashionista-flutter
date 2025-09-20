import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';

class TrendCommentBlocState extends Equatable {
  const TrendCommentBlocState();
  @override
  List<Object?> get props => [];
}

class TrendCommentInitial extends TrendCommentBlocState {
  const TrendCommentInitial();
}

class TrendCommentLoading extends TrendCommentBlocState {
  const TrendCommentLoading();
}

class TrendCommentLoaded extends TrendCommentBlocState {
  final CommentModel comment;
  const TrendCommentLoaded(this.comment);

  @override
  List<Object?> get props => [comment];
}

class TrendCommentsLoaded extends TrendCommentBlocState {
  final List<CommentModel> comments;
  final bool fromCache;
  const TrendCommentsLoaded(this.comments, {this.fromCache = false});

  @override
  List<Object?> get props => [comments];
}

class TrendCommentsEmpty extends TrendCommentBlocState {
  const TrendCommentsEmpty();
}

class TrendCommentError extends TrendCommentBlocState {
  final String message;
  const TrendCommentError(this.message);

  @override
  List<Object?> get props => [message];
}
