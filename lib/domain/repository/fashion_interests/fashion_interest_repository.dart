import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';

/// Catalogue of fashion interests, served cache-first.
abstract class FashionInterestRepository {
  /// Interests held in the local cache, or `null` when nothing is stored.
  List<FashionInterestModel>? get cached;

  /// Whether [cached] is still inside its TTL.
  bool get isCacheFresh;

  /// Returns the catalogue, newest snapshot first.
  ///
  /// A fresh cache answers without touching the network. When the cache is
  /// missing or stale — or [forceRefresh] is set — Firebase is queried and the
  /// snapshot replaced. A failed fetch falls back to stale cache when present.
  Future<Either<String, List<FashionInterestModel>>> fetch({
    bool forceRefresh = false,
  });
}
