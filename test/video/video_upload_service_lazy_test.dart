import 'package:dio/dio.dart';
import 'package:fashionista/data/services/firebase/firebase_video_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression: `initialiseDependencies()` runs before `Firebase.initializeApp()`,
  // so constructing this service used to throw `[core/no-app]` at startup.
  test('can be constructed before Firebase is initialized', () {
    expect(FirebaseVideoUploadService.new, returnsNormally);
    expect(() => FirebaseVideoUploadService(dio: Dio()), returnsNormally);
  });

  test('fails with a user-facing error when Firebase is unavailable', () async {
    final service = FirebaseVideoUploadService(dio: Dio());

    await expectLater(
      service.requestSignature('trend_123456'),
      throwsA(isA<VideoUploadException>()),
    );
  });
}
