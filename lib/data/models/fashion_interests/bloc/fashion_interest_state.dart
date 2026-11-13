import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';

/// Catalogue shown in the composer's interest panel.
class FashionInterestState extends Equatable {
  /// Every interest, sorted by popularity.
  final List<FashionInterestModel> all;

  /// The subset matching [query]; equal to [all] when the query is empty.
  final List<FashionInterestModel> visible;

  final bool isLoading;

  /// Only set when there is nothing cached to show instead.
  final String? error;

  /// The visible data came from the local snapshot.
  final bool fromCache;

  /// Lowercased filter currently applied.
  final String query;

  const FashionInterestState({
    this.all = const [],
    this.visible = const [],
    this.isLoading = false,
    this.error,
    this.fromCache = false,
    this.query = '',
  });

  bool get isEmpty => all.isEmpty;

  FashionInterestState copyWith({
    List<FashionInterestModel>? all,
    List<FashionInterestModel>? visible,
    bool? isLoading,
    String? error,
    bool? fromCache,
    String? query,
    bool clearError = false,
  }) {
    return FashionInterestState(
      all: all ?? this.all,
      visible: visible ?? this.visible,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      fromCache: fromCache ?? this.fromCache,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [all, visible, isLoading, error, fromCache, query];
}
