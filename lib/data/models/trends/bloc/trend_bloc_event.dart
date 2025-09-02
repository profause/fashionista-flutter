import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';

abstract class TrendBlocEvent extends Equatable {
  const TrendBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrend extends TrendBlocEvent {
  final String uid;
  const LoadTrend(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateTrend extends TrendBlocEvent {
  final TrendFeedModel trend;
  const UpdateTrend(this.trend);

  @override
  List<Object?> get props => [trend];
}

class LoadTrends extends TrendBlocEvent {
  final String uid;
  const LoadTrends(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadTrendsCacheFirstThenNetwork extends TrendBlocEvent {
  final String uid;
  const LoadTrendsCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteTrend extends TrendBlocEvent {
  final String uid;
  const DeleteTrend(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ClearTrend extends TrendBlocEvent {
  const ClearTrend();
}
