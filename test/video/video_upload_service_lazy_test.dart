import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fashionista/data/models/video/video_upload_models.dart';
import 'package:fashionista/data/services/firebase/firebase_video_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression: `initialiseDependencies()` runs before `Firebase.initializeApp()`,
  // so constructing this service used to throw `[core/no-app]` at startup.
  test('can be constructed before Firebase is initialized', () {
    expect(FirebaseVideoUploadService.new, returnsNormally);
    expect(() => FirebaseVideoUploadService(dio: Dio()), returnsNormally);
  });

  test('fails with a user-facing error when the config is missing', () async {
    // No Firebase app and no Remote Config in this test, so the cloud name
    // resolves to an empty string.
    final service = FirebaseVideoUploadService(
      dio: Dio(),
      currentUserId: () => 'u1',
    );

    await expectLater(
      service.upload(file: File('/tmp/fashionista-missing.mp4')),
      throwsA(
        isA<VideoUploadException>().having(
          (error) => error.message,
          'message',
          contains('not configured'),
        ),
      ),
    );
  });

  test('deleteAsset swallows the missing Firebase app', () async {
    final service = FirebaseVideoUploadService(dio: Dio());

    expect(
      await service.deleteAsset(assetId: 'a/b', trendId: 'trend_1'),
      isFalse,
    );
  });

  test('config falls back to the app-wide preset and base folder', () {
    const config = VideoUploadConfig(
      cloudName: 'demo',
      uploadPreset: FirebaseVideoUploadService.defaultUploadPreset,
      baseFolder: FirebaseVideoUploadService.defaultBaseFolder,
    );

    expect(config.isComplete, isTrue);
    // Mirrors trendVideoFolder() in functions/src/cloudinary/folder.ts.
    expect(config.folderFor('u1'), 'fashionista/trends/videos/u1');
  });
}
