import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/data/repository/fashion_interests/fashion_interest_repository_impl.dart';
import 'package:fashionista/data/services/firebase/firebase_fashion_interest_service.dart';
import 'package:fashionista/data/services/hive/fashion_interest_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _FakeFashionInterestService implements FirebaseFashionInterestService {
  @override
  Future<Either<String, Map<String, List<FashionInterestModel>>>>
  fetchFashionInterests() async =>
      const Right<String, Map<String, List<FashionInterestModel>>>({});

  @override
  Future<Either<String, List<FashionInterestModel>>> searchInterestsByName(
    String name,
  ) async => const Right<String, List<FashionInterestModel>>([]);
}

void main() {
  late Directory directory;
  late Box box;
  late FashionInterestCache cache;
  late FashionInterestRepositoryImpl repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fashionista_reports');
    Hive.init(directory.path);
    box = await Hive.openBox('fashion_interests_repository_test');
    cache = FashionInterestCache(box: box);
    repository = FashionInterestRepositoryImpl(
      cache: cache,
      service: _FakeFashionInterestService(),
    );
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('increments cached counters case-insensitively', () async {
    await cache.write(const [
      FashionInterestModel(category: 'a', name: 'Ankara', numberOfPosts: 2),
      FashionInterestModel(category: 'a', name: 'Crop Top', numberOfPosts: 5),
      FashionInterestModel(category: 'a', name: 'Lace', numberOfPosts: 1),
    ]);

    await repository.incrementCachedPostCounts([
      'ankara',
      'CROP   TOP',
      'missing',
    ]);

    final counts = {
      for (final interest in cache.read()!)
        interest.name: interest.numberOfPosts,
    };
    expect(counts['Ankara'], 3);
    expect(counts['Crop Top'], 6);
    expect(counts['Lace'], 1);
  });

  test('does nothing when the cache is empty', () async {
    await repository.incrementCachedPostCounts(['Ankara']);

    expect(cache.read(), isNull);
  });
}
