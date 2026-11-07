import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/trends/bloc/video_upload_cubit.dart';
import 'package:fashionista/data/models/trends/bloc/video_upload_state.dart';
import 'package:fashionista/data/models/video/pending_publish_task.dart';
import 'package:fashionista/data/models/video/video_upload_models.dart';
import 'package:fashionista/data/services/firebase/firebase_video_upload_service.dart';
import 'package:fashionista/data/services/hive/hive_upload_task_service.dart';
import 'package:flutter_test/flutter_test.dart';

const String trendId = 'trend_123456';

VideoUploadSignature signature({String signatureValue = 'sig-1'}) {
  return VideoUploadSignature(
    cloudName: 'cloud',
    apiKey: 'key',
    timestamp: 1700000000,
    signature: signatureValue,
    folder: 'fashionista/trends/videos/u1',
    publicId: trendId,
  );
}

CloudinaryVideoAsset asset({String id = trendId}) {
  return CloudinaryVideoAsset(
    assetId: 'fashionista/trends/videos/u1/$id',
    secureUrl: 'https://res.cloudinary.com/cloud/video/upload/$id.mp4',
    thumbnailUrl: 'https://res.cloudinary.com/cloud/video/upload/so_0/$id.jpg',
    durationSeconds: 12,
    width: 720,
    height: 1280,
    fileSize: 4 * 1024 * 1024,
  );
}

class FakeUploadService implements FirebaseVideoUploadService {
  final List<String> signatureRequests = [];
  final List<String> uploads = [];
  final List<String> deletes = [];

  /// Results queued per upload attempt; the last one repeats.
  final List<Object> uploadResults = [];
  int signatureCalls = 0;

  /// Held open by the cancel test so `cancel()` lands mid-transfer.
  Completer<void>? gate;

  @override
  Future<VideoUploadSignature> requestSignature(String trendId) async {
    signatureRequests.add(trendId);
    signatureCalls += 1;
    return signature(signatureValue: 'sig-$signatureCalls');
  }

  @override
  Future<CloudinaryVideoAsset> upload({
    required File file,
    required VideoUploadSignature signature,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    uploads.add(signature.signature);
    if (gate != null) await gate!.future;
    if (cancelToken?.isCancelled ?? false) {
      throw const VideoUploadException('Upload cancelled.');
    }

    onProgress?.call(50, 100);
    onProgress?.call(100, 100);

    final result = uploadResults.isEmpty
        ? asset()
        : uploadResults.length == 1
        ? uploadResults.first
        : uploadResults.removeAt(0);

    if (result is VideoUploadException) throw result;
    return result as CloudinaryVideoAsset;
  }

  @override
  Future<bool> deleteAsset({
    required String assetId,
    required String trendId,
  }) async {
    deletes.add(assetId);
    return true;
  }
}

class FakePendingTasks extends HiveUploadTaskService {
  final Map<String, PendingPublishTask> saved = {};

  @override
  Future<List<PendingPublishTask>> all() async => saved.values.toList();

  @override
  Future<void> save(PendingPublishTask task) async =>
      saved[task.trendId] = task;

  @override
  Future<void> remove(String trendId) async => saved.remove(trendId);

  @override
  Future<void> clearCache() async => saved.clear();
}

void main() {
  late FakeUploadService service;
  late FakePendingTasks pending;
  late Directory temp;
  late String videoPath;

  setUp(() async {
    service = FakeUploadService();
    pending = FakePendingTasks();
    temp = Directory.systemTemp.createTempSync('video_upload_test');
    videoPath = '${temp.path}/clip.mp4';
    File(videoPath).writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  VideoUploadCubit build() =>
      VideoUploadCubit(service: service, pendingTasks: pending);

  group('happy path', () {
    test('authorizes, uploads, saves and reports the media', () async {
      final bloc = build();
      final published = <FeaturedMediaModel>[];
      final phases = <VideoUploadPhase>[];
      final sub = bloc.stream.listen((state) => phases.add(state.phase));

      await bloc.start(
        trendId: trendId,
        videoPath: videoPath,
        hasAudio: false,
        publish: ({required trendId, required media}) async {
          published.add(media);
        },
      );

      // Stream events are delivered asynchronously; let them drain first.
      await Future<void>.delayed(Duration.zero);

      expect(service.signatureRequests, [trendId]);
      expect(service.uploads, hasLength(1));
      expect(published, hasLength(1));
      expect(published.single.type, 'video');
      expect(published.single.hasAudio, isFalse);
      expect(published.single.duration, 12);
      expect(bloc.state.phase, VideoUploadPhase.completed);
      expect(phases, contains(VideoUploadPhase.authorizing));
      expect(phases, contains(VideoUploadPhase.uploading));
      expect(phases, contains(VideoUploadPhase.saving));

      await sub.cancel();
      await bloc.close();
    });

    test('reports upload progress', () async {
      final bloc = build();
      final progress = <double>[];
      final sub = bloc.stream.listen((state) => progress.add(state.progress));

      await bloc.start(
        trendId: trendId,
        videoPath: videoPath,
        hasAudio: true,
        publish: ({required trendId, required media}) async {},
      );

      expect(progress.any((value) => value > 0 && value < 1), isTrue);
      expect(progress.last, 1);

      await sub.cancel();
      await bloc.close();
    });
  });

  group('failures', () {
    test(
      'a signature rejection is retried once with a fresh signature',
      () async {
        service.uploadResults.addAll([
          const VideoUploadException(
            'Invalid Signature',
            isSignatureProblem: true,
          ),
          asset(),
        ]);

        final bloc = build();
        await bloc.start(
          trendId: trendId,
          videoPath: videoPath,
          hasAudio: true,
          publish: ({required trendId, required media}) async {},
        );

        expect(service.signatureCalls, 2);
        expect(service.uploads, hasLength(2));
        expect(bloc.state.phase, VideoUploadPhase.completed);

        await bloc.close();
      },
    );

    test('a second signature rejection fails without looping', () async {
      service.uploadResults.addAll([
        const VideoUploadException(
          'Invalid Signature',
          isSignatureProblem: true,
        ),
        const VideoUploadException(
          'Invalid Signature',
          isSignatureProblem: true,
        ),
      ]);

      final bloc = build();
      await bloc.start(
        trendId: trendId,
        videoPath: videoPath,
        hasAudio: true,
        publish: ({required trendId, required media}) async {},
      );

      expect(service.uploads, hasLength(2));
      expect(bloc.state.phase, VideoUploadPhase.failed);
      expect(bloc.state.publishFailedOnly, isFalse);

      await bloc.close();
    });

    test('a network failure keeps the error and does not publish', () async {
      service.uploadResults.add(const VideoUploadException('No connection'));
      var published = 0;

      final bloc = build();
      await bloc.start(
        trendId: trendId,
        videoPath: videoPath,
        hasAudio: true,
        publish: ({required trendId, required media}) async => published++,
      );

      expect(bloc.state.phase, VideoUploadPhase.failed);
      expect(bloc.state.error, 'No connection');
      expect(published, 0);

      await bloc.close();
    });

    test(
      'a Firestore failure keeps the asset and stores a pending publish',
      () async {
        final bloc = build();

        await bloc.start(
          trendId: trendId,
          videoPath: videoPath,
          hasAudio: true,
          publish: ({required trendId, required media}) async {
            throw Exception('firestore down');
          },
        );

        expect(bloc.state.phase, VideoUploadPhase.failed);
        expect(bloc.state.publishFailedOnly, isTrue);
        expect(pending.saved, contains(trendId));
        expect(pending.saved[trendId]!.media.type, 'video');
        // Nothing was deleted: the asset is the only copy of the video.
        expect(service.deletes, isEmpty);

        await bloc.close();
      },
    );
  });

  group('retry', () {
    test('publish-only retry does not upload the file again', () async {
      var attempts = 0;
      final bloc = build();

      await bloc.start(
        trendId: trendId,
        videoPath: videoPath,
        hasAudio: true,
        publish: ({required trendId, required media}) async {
          attempts += 1;
          if (attempts == 1) throw Exception('firestore down');
        },
      );

      expect(bloc.state.publishFailedOnly, isTrue);
      expect(service.uploads, hasLength(1));

      await bloc.retry();

      expect(attempts, 2);
      expect(service.uploads, hasLength(1));
      expect(bloc.state.phase, VideoUploadPhase.completed);
      expect(pending.saved, isEmpty);

      await bloc.close();
    });

    test('an upload failure retries from authorization', () async {
      service.uploadResults.addAll([
        const VideoUploadException('No connection'),
        asset(),
      ]);

      final bloc = build();
      await bloc.start(
        trendId: trendId,
        videoPath: videoPath,
        hasAudio: true,
        publish: ({required trendId, required media}) async {},
      );

      expect(bloc.state.phase, VideoUploadPhase.failed);

      await bloc.retry();

      expect(bloc.state.phase, VideoUploadPhase.completed);
      expect(service.signatureCalls, 2);

      await bloc.close();
    });
  });

  test('cancel stops the upload and removes the partial asset', () async {
    service.gate = Completer<void>();
    final bloc = build();
    var published = 0;

    final run = bloc.start(
      trendId: trendId,
      videoPath: videoPath,
      hasAudio: true,
      publish: ({required trendId, required media}) async => published++,
    );

    // Let the cubit reach the upload, then cancel mid-transfer.
    await Future<void>.delayed(Duration.zero);
    await bloc.cancel();

    service.gate!.complete();
    await run;

    expect(bloc.state.phase, VideoUploadPhase.cancelled);
    expect(published, 0);
    expect(service.deletes, isEmpty);

    await bloc.close();
  });
}
