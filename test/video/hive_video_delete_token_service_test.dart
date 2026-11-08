import 'dart:convert';
import 'dart:io';

import 'package:fashionista/data/services/hive/hive_video_delete_token_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const String assetId = 'fashionista/trends/videos/u1/abc';

void main() {
  late Directory temp;
  late Box<String> box;
  late HiveVideoDeleteTokenService service;

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('delete_token_test');
    Hive.init(temp.path);
    box = await Hive.openBox<String>('video_delete_tokens_test');
    service = HiveVideoDeleteTokenService(box: box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteFromDisk();
    temp.deleteSync(recursive: true);
  });

  test('returns a token saved moments ago', () async {
    await service.save(assetId: assetId, token: 'tok-1');

    expect(await service.tokenFor(assetId), 'tok-1');
  });

  test('returns null for an unknown asset', () async {
    expect(await service.tokenFor(assetId), isNull);
  });

  test('ignores a token older than the 10 minute window', () async {
    // Cloudinary only honours the token for 10 minutes.
    final uploadedAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 11))
        .toIso8601String();
    await box.put(
      assetId,
      jsonEncode({'token': 'tok-old', 'uploadedAt': uploadedAt}),
    );

    expect(await service.tokenFor(assetId), isNull);
    // The expired entry is cleaned up on read.
    expect(box.containsKey(assetId), isFalse);
  });

  test('save prunes expired entries', () async {
    final uploadedAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 30))
        .toIso8601String();
    await box.put(
      'stale',
      jsonEncode({'token': 'x', 'uploadedAt': uploadedAt}),
    );

    await service.save(assetId: assetId, token: 'tok-2');

    expect(box.containsKey('stale'), isFalse);
    expect(await service.tokenFor(assetId), 'tok-2');
  });

  test('remove deletes the entry', () async {
    await service.save(assetId: assetId, token: 'tok-1');
    await service.remove(assetId);

    expect(await service.tokenFor(assetId), isNull);
  });

  test('survives a corrupt entry', () async {
    await box.put(assetId, 'not json');

    expect(await service.tokenFor(assetId), isNull);
  });
}
