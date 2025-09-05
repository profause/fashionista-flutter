import 'package:equatable/equatable.dart';

abstract class TrendCommentBlocEvent extends Equatable {
  const TrendCommentBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrend extends TrendCommentBlocEvent {
  final String uid;
  const LoadTrend(this.uid);

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
