import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/fashion_interests/bloc/fashion_interest_cubit.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/domain/repository/fashion_interests/fashion_interest_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFashionInterestRepository implements FashionInterestRepository {
  @override
  List<FashionInterestModel>? cached;

  @override
  bool isCacheFresh = false;

  Either<String, List<FashionInterestModel>> response =
      const Right<String, List<FashionInterestModel>>(<FashionInterestModel>[]);

  int fetchCalls = 0;
  bool? lastForceRefresh;

  @override
  Future<Either<String, List<FashionInterestModel>>> fetch({
    bool forceRefresh = false,
  }) async {
    fetchCalls++;
    lastForceRefresh = forceRefresh;
    return response;
  }
}

FashionInterestModel interest(String name, int posts) {
  return FashionInterestModel(
    category: 'category',
    name: name,
    numberOfPosts: posts,
  );
}

void main() {
  late FakeFashionInterestRepository repository;
  late FashionInterestCubit cubit;

  setUp(() {
    repository = FakeFashionInterestRepository();
    cubit = FashionInterestCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('paints a fresh cache without a network call', () async {
    repository.cached = [
      interest('linen', 5),
      interest('summer', 20),
      interest('crop top', 1),
    ];
    repository.isCacheFresh = true;

    await cubit.load();

    expect(repository.fetchCalls, 0);
    expect(cubit.state.fromCache, isTrue);
    expect(cubit.state.all.map((item) => item.name), [
      'summer',
      'linen',
      'crop top',
    ]);
  });

  test(
    'refreshes a stale cache and replaces it with the network list',
    () async {
      repository.cached = [interest('old', 1)];
      repository.isCacheFresh = false;
      repository.response = Right<String, List<FashionInterestModel>>([
        interest('fresh', 10),
      ]);

      await cubit.load();

      expect(repository.fetchCalls, 1);
      expect(cubit.state.fromCache, isFalse);
      expect(cubit.state.all.map((item) => item.name), ['fresh']);
    },
  );

  test('keeps the stale cache when the refresh fails', () async {
    repository.cached = [interest('linen', 5)];
    repository.isCacheFresh = false;
    repository.response = const Left<String, List<FashionInterestModel>>(
      'offline',
    );

    await cubit.load();

    expect(cubit.state.all.map((item) => item.name), ['linen']);
    expect(cubit.state.error, isNull);
    expect(cubit.state.isLoading, isFalse);
  });

  test('reports an error when there is no cache to fall back to', () async {
    repository.response = const Left<String, List<FashionInterestModel>>(
      'offline',
    );

    await cubit.load();

    expect(cubit.state.error, 'offline');
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.all, isEmpty);
  });

  test('forces a refresh when asked', () async {
    repository.cached = [interest('linen', 5)];
    repository.isCacheFresh = true;
    repository.response = Right<String, List<FashionInterestModel>>([
      interest('summer', 20),
    ]);

    await cubit.load(forceRefresh: true);

    expect(repository.fetchCalls, 1);
    expect(cubit.state.all.map((item) => item.name), ['summer']);
  });

  test('filters locally, prefix matches first', () async {
    repository.cached = [
      interest('resort summer', 2),
      interest('summer', 20),
      interest('linen', 5),
    ];
    repository.isCacheFresh = true;

    await cubit.load();
    cubit.filter('summer');

    expect(repository.fetchCalls, 0);
    expect(cubit.state.query, 'summer');
    expect(cubit.state.visible.map((item) => item.name), [
      'summer',
      'resort summer',
    ]);
  });

  test('an empty query restores the full list', () async {
    repository.cached = [interest('summer', 20), interest('linen', 5)];
    repository.isCacheFresh = true;

    await cubit.load();
    cubit.filter('summer');
    cubit.filter('  ');

    expect(cubit.state.visible.length, 2);
  });

  test('substring matches are kept after prefix matches', () async {
    repository.cached = [
      interest('Oversized summer dress', 3),
      interest('summer', 9),
      interest('linen', 7),
    ];
    repository.isCacheFresh = true;

    await cubit.load();
    cubit.filter('sum');

    expect(cubit.state.visible.map((item) => item.name), [
      'summer',
      'Oversized summer dress',
    ]);
  });
}
