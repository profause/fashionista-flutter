import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/data/services/firebase/firebase_fashion_interest_service.dart';
import 'package:fashionista/data/services/hive/fashion_interest_cache.dart';
import 'package:fashionista/domain/repository/fashion_interests/fashion_interest_repository.dart';

class FashionInterestRepositoryImpl implements FashionInterestRepository {
  FashionInterestRepositoryImpl({
    required FashionInterestCache cache,
    required FirebaseFashionInterestService service,
  }) : _cache = cache,
       _service = service;

  final FashionInterestCache _cache;
  final FirebaseFashionInterestService _service;

  Future<Either<String, List<FashionInterestModel>>>? _inFlight;

  @override
  List<FashionInterestModel>? get cached => _cache.read();

  @override
  bool get isCacheFresh => _cache.isFresh;

  @override
  Future<Either<String, List<FashionInterestModel>>> fetch({
    bool forceRefresh = false,
  }) {
    final cached = _cache.read();
    if (!forceRefresh && cached != null && _cache.isFresh) {
      return Future.value(Right<String, List<FashionInterestModel>>(cached));
    }

    // Both the tag icon and a '#' keystroke can ask at once; share the request.
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchAndCache();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return future;
  }

  Future<Either<String, List<FashionInterestModel>>> _fetchAndCache() async {
    final result = await _service.fetchFashionInterests();

    return result.fold(
      (error) async {
        // A stale list beats an empty panel when the network is down.
        final stale = _cache.read();
        if (stale != null) {
          return Right<String, List<FashionInterestModel>>(stale);
        }
        return Left<String, List<FashionInterestModel>>(error);
      },
      (grouped) async {
        final flat = <FashionInterestModel>[
          for (final interests in grouped.values) ...interests,
        ]..sort(_byPopularity);

        await _cache.write(flat);
        return Right<String, List<FashionInterestModel>>(flat);
      },
    );
  }

  static int _byPopularity(FashionInterestModel a, FashionInterestModel b) {
    final byPosts = b.numberOfPosts.compareTo(a.numberOfPosts);
    if (byPosts != 0) return byPosts;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
