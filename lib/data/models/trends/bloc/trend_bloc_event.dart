import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';

abstract class TrendBlocEvent extends Equatable {
  const TrendBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrend extends TrendBlocEvent {
  final String uid;
  final bool isFromCache;
  const LoadTrend(this.uid, {this.isFromCache = false});

  @override
  List<Object?> get props => [uid, isFromCache];
}

class UpdateTrend extends TrendBlocEvent {
  final TrendFeedModel trend;
  const UpdateTrend(this.trend);

  @override
  List<Object?> get props => [trend];
}

class AddTrend extends TrendBlocEvent {
  final TrendFeedModel trend;
  const AddTrend(this.trend);
  @override
  List<Object?> get props => [trend];
}

class UpdateCachedTrend extends TrendBlocEvent {
  final TrendFeedModel trend;
  const UpdateCachedTrend(this.trend);

  @override
  List<Object?> get props => [trend];
}

class LoadTrendsCacheForYouPage extends TrendBlocEvent {
  final String uid;
  const LoadTrendsCacheForYouPage(this.uid);

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
