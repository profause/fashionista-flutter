import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';

class TrendBlocState extends Equatable {
  const TrendBlocState();
  @override
  List<Object?> get props => [];
}

class TrendInitial extends TrendBlocState {
  const TrendInitial();
}

class TrendLoading extends TrendBlocState {
  const TrendLoading();
}

class TrendLoaded extends TrendBlocState {
  final TrendFeedModel trend;
  const TrendLoaded(this.trend);

  @override
  List<Object?> get props => [trend];
}

class TrendUpdated extends TrendBlocState {
  final TrendFeedModel trend;
  const TrendUpdated(this.trend);
  @override
  List<Object?> get props => [trend];
}

class TrendAdded extends TrendBlocState {
  final TrendFeedModel trend;
  const TrendAdded(this.trend);
  @override
  List<Object?> get props => [trend];
}

class TrendsCreatedByLoaded extends TrendBlocState {
  final List<TrendFeedModel> trends;
  final bool fromCache;
  const TrendsCreatedByLoaded(this.trends, {this.fromCache = false});

  @override
  List<Object?> get props => [trends];
}

class TrendsEmpty extends TrendBlocState {
  const TrendsEmpty();
}

class TrendError extends TrendBlocState {
  final String message;
  const TrendError(this.message);

  @override
  List<Object?> get props => [message];
}

class TrendDeleted extends TrendBlocState {
  final String message;
  const TrendDeleted(this.message);
  @override
  List<Object?> get props => [message];
}
