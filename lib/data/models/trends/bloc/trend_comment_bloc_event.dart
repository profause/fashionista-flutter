import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';

abstract class TrendCommentBlocEvent extends Equatable {
  const TrendCommentBlocEvent();

  @override
  List<Object?> get props => [];
}

class AddTrendComment extends TrendCommentBlocEvent {
  final CommentModel comment;
  const AddTrendComment(this.comment);
  @override
  List<Object?> get props => [comment];
}

class LoadTrendComment extends TrendCommentBlocEvent {
  final String uid;
  const LoadTrendComment(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadTrendComments extends TrendCommentBlocEvent {
  final String refId;
  const LoadTrendComments(this.refId);

  @override
  List<Object?> get props => [refId];
}

class LoadTrendCommentsCacheFirstThenNetwork extends TrendCommentBlocEvent {
  final String refId;
  const LoadTrendCommentsCacheFirstThenNetwork(this.refId);

  @override
  List<Object?> get props => [refId];
}

class ClearTrendComment extends TrendCommentBlocEvent {
  const ClearTrendComment();
}
