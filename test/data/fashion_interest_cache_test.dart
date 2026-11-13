import 'dart:io';

import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/data/services/hive/fashion_interest_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory directory;
  late Box box;
  late FashionInterestCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fashionista_interests');
    Hive.init(directory.path);
    box = await Hive.openBox('fashion_interests_test');
    cache = FashionInterestCache(box: box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('round-trips interests and marks the snapshot fresh', () async {
    await cache.write([
      const FashionInterestModel(
        category: 'tops',
        name: 'crop top',
        numberOfPosts: 12,
      ),
    ]);

    final restored = cache.read();

    expect(restored, isNotNull);
    expect(restored!.single.name, 'crop top');
    expect(restored.single.category, 'tops');
    expect(restored.single.numberOfPosts, 12);
    expect(cache.isFresh, isTrue);
  });

  test('treats a snapshot older than the TTL as stale', () async {
    await cache.write([
      const FashionInterestModel(category: '', name: 'linen'),
    ]);
    await box.put(
      FashionInterestCache.fetchedAtKey,
      DateTime.now().subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
    );

    expect(cache.read(), isNotEmpty);
    expect(cache.isFresh, isFalse);
  });

  test('ignores a corrupt snapshot', () async {
    await box.put(FashionInterestCache.snapshotKey, 'not json');

    expect(cache.read(), isNull);
  });

  test('reports no cache on an empty box', () {
    expect(cache.read(), isNull);
    expect(cache.isFresh, isFalse);
  });
}
