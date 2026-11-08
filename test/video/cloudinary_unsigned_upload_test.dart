import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fashionista/data/models/video/video_upload_models.dart';
import 'package:fashionista/data/services/firebase/firebase_video_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

const VideoUploadConfig config = VideoUploadConfig(
  cloudName: 'demo-cloud',
  uploadPreset: 'trend_videos',
  baseFolder: 'fashionista',
);

/// Captures the outgoing request and answers with [response].
class _CapturingInterceptor extends Interceptor {
  _CapturingInterceptor(this.response);

  final Response<Map<String, dynamic>> response;
  RequestOptions? captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured = options;
    handler.resolve(response);
  }
}

Response<Map<String, dynamic>> _ok(Map<String, dynamic> body) =>
    Response(requestOptions: RequestOptions(), statusCode: 200, data: body);

void main() {
  late Directory temp;
  late File file;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('unsigned_upload_test');
    file = File('${temp.path}/clip.mp4')..writeAsBytesSync([0, 1, 2, 3]);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('uploads with the preset and no signature parameters', () async {
    final interceptor = _CapturingInterceptor(
      _ok({
        'public_id': 'fashionista/trends/videos/u1/generated-id',
        'secure_url':
            'https://res.cloudinary.com/demo-cloud/video/upload/a.mp4',
        'duration': 9.5,
        'width': 720,
        'height': 1280,
        'bytes': 2048,
        'delete_token': 'tok-1',
      }),
    );
    final dio = Dio()..interceptors.add(interceptor);
    final service = FirebaseVideoUploadService(
      dio: dio,
      config: config,
      currentUserId: () => 'u1',
    );

    final asset = await service.upload(file: file);

    final request = interceptor.captured!;
    expect(request.uri.host, 'api.cloudinary.com');
    expect(request.uri.path, '/v1_1/demo-cloud/video/upload');

    final form = request.data as FormData;
    final fields = {for (final entry in form.fields) entry.key: entry.value};
    expect(fields['upload_preset'], 'trend_videos');
    expect(fields['folder'], 'fashionista/trends/videos/u1');
    expect(fields['public_id'], isNotEmpty);
    // Nothing signed may be sent: a stray param invalidates nothing here, but
    // it would mean signing crept back in.
    expect(fields.containsKey('signature'), isFalse);
    expect(fields.containsKey('api_key'), isFalse);
    expect(fields.containsKey('timestamp'), isFalse);
    expect(form.files.single.key, 'file');

    expect(asset.deleteToken, 'tok-1');
    expect(asset.hasDeleteToken, isTrue);
    expect(asset.durationSeconds, 9.5);
    expect(asset.assetId, 'fashionista/trends/videos/u1/generated-id');
  });

  test('uses a different public id per attempt', () async {
    final ids = <String>[];

    for (var attempt = 0; attempt < 2; attempt++) {
      final interceptor = _CapturingInterceptor(_ok({'secure_url': 'u'}));
      final service = FirebaseVideoUploadService(
        dio: Dio()..interceptors.add(interceptor),
        config: config,
        currentUserId: () => 'u1',
      );

      await service.upload(file: file);
      final form = interceptor.captured!.data as FormData;
      ids.add(
        form.fields.firstWhere((entry) => entry.key == 'public_id').value,
      );
    }

    // Unsigned uploads never overwrite, so a repeated id would collide.
    expect(ids.toSet(), hasLength(2));
  });

  test('surfaces the Cloudinary error message', () async {
    final interceptor = _CapturingInterceptor(
      Response(
        requestOptions: RequestOptions(),
        statusCode: 400,
        data: {
          'error': {'message': 'Upload preset not found'},
        },
      ),
    );
    final service = FirebaseVideoUploadService(
      dio: Dio()..interceptors.add(interceptor),
      config: config,
      currentUserId: () => 'u1',
    );

    await expectLater(
      service.upload(file: file),
      throwsA(
        isA<VideoUploadException>().having(
          (error) => error.message,
          'message',
          'Upload preset not found',
        ),
      ),
    );
  });

  test('refuses to upload without a signed-in user', () async {
    final service = FirebaseVideoUploadService(
      dio: Dio(),
      config: config,
      currentUserId: () => null,
    );

    await expectLater(
      service.upload(file: file),
      throwsA(isA<VideoUploadException>()),
    );
  });

  test('deletes by token against delete_by_token', () async {
    final interceptor = _CapturingInterceptor(_ok({'result': 'ok'}));
    final service = FirebaseVideoUploadService(
      dio: Dio()..interceptors.add(interceptor),
      config: config,
      currentUserId: () => 'u1',
    );

    expect(await service.deleteByToken('tok-1'), isTrue);

    final request = interceptor.captured!;
    expect(request.uri.path, '/v1_1/demo-cloud/delete_by_token');
    expect(request.data, {'token': 'tok-1'});
  });

  test('reports a rejected token delete', () async {
    final interceptor = _CapturingInterceptor(
      Response(
        requestOptions: RequestOptions(),
        statusCode: 401,
        data: {'result': 'token expired'},
      ),
    );
    final service = FirebaseVideoUploadService(
      dio: Dio()..interceptors.add(interceptor),
      config: config,
      currentUserId: () => 'u1',
    );

    expect(await service.deleteByToken('tok-old'), isFalse);
  });
}
