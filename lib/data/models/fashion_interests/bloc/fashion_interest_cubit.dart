import 'package:fashionista/data/models/fashion_interests/bloc/fashion_interest_state.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/domain/repository/fashion_interests/fashion_interest_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cache-first catalogue for the composer's interest panel.
///
/// Filtering is always local: the panel must respond to every keystroke without
/// touching Firestore.
class FashionInterestCubit extends Cubit<FashionInterestState> {
  FashionInterestCubit({required FashionInterestRepository repository})
    : _repository = repository,
      super(const FashionInterestState());

  final FashionInterestRepository _repository;

  /// Paints the cache first, then refreshes it when stale.
  Future<void> load({bool forceRefresh = false}) async {
    if (isClosed) return;

    final cached = _repository.cached;

    if (cached != null && cached.isNotEmpty) {
      _emitData(cached, fromCache: true);
      if (!forceRefresh && _repository.isCacheFresh) return;
    } else {
      emit(state.copyWith(isLoading: true, clearError: true));
    }

    final result = await _repository.fetch(forceRefresh: forceRefresh);
    if (isClosed) return;

    result.fold(
      (error) => emit(
        state.copyWith(
          isLoading: false,
          error: state.all.isEmpty ? error : null,
        ),
      ),
      (interests) => _emitData(interests, fromCache: false),
    );
  }

  /// Filters the cached catalogue; never performs I/O.
  void filter(String query) {
    if (isClosed) return;

    final normalized = query.trim().toLowerCase();
    emit(
      state.copyWith(query: normalized, visible: _rank(state.all, normalized)),
    );
  }

  void _emitData(
    List<FashionInterestModel> interests, {
    required bool fromCache,
  }) {
    final sorted = [...interests]..sort(_byPopularity);

    emit(
      state.copyWith(
        all: sorted,
        visible: _rank(sorted, state.query),
        isLoading: false,
        fromCache: fromCache,
        clearError: true,
      ),
    );
  }

  static int _byPopularity(FashionInterestModel a, FashionInterestModel b) {
    final byPosts = b.numberOfPosts.compareTo(a.numberOfPosts);
    if (byPosts != 0) return byPosts;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Prefix matches first, then substring matches; both keep popularity order.
  static List<FashionInterestModel> _rank(
    List<FashionInterestModel> all,
    String query,
  ) {
    if (query.isEmpty) return all;

    final prefix = <FashionInterestModel>[];
    final contains = <FashionInterestModel>[];

    for (final interest in all) {
      final name = interest.name.toLowerCase();
      if (name.startsWith(query)) {
        prefix.add(interest);
      } else if (name.contains(query)) {
        contains.add(interest);
      }
    }

    return [...prefix, ...contains];
  }
}
