import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:fashionista/data/models/video/video_upload_models.dart';
import 'package:flutter/foundation.dart';

/// Thrown for anything the user can act on (network, signature, rejection).
class VideoUploadException implements Exception {
  final String message;
  final bool isSignatureProblem;

  const VideoUploadException(this.message, {this.isSignatureProblem = false});

  @override
  String toString() => message;
}

/// Signed Cloudinary video uploads.
///
/// The API secret never leaves the backend: this service only ever sees a
/// signature, and it re-requests one instead of retrying a rejected upload with
/// stale parameters (plan §6.5).
class FirebaseVideoUploadService {
  FirebaseVideoUploadService({Dio? dio, FirebaseFunctions? functions})
    : _dio = dio ?? Dio(),
      _providedFunctions = functions;

  static const String signatureCallable = 'createVideoUploadSignature';
  static const String deleteCallable = 'deleteCloudinaryAsset';

  final Dio _dio;
  final FirebaseFunctions? _providedFunctions;

  /// Resolved on first use, never in the constructor: this service is built by
  /// the service locator *before* `Firebase.initializeApp()`, and touching
  /// `FirebaseFunctions.instance` there throws `[core/no-app]`.
  FirebaseFunctions get _functions =>
      _providedFunctions ?? FirebaseFunctions.instance;

  Future<VideoUploadSignature> requestSignature(String trendId) async {
    try {
      final result = await _functions.httpsCallable(signatureCallable).call({
        'trendId': trendId,
      });

      final signature = VideoUploadSignature.fromMap(
        (result.data as Map).cast<dynamic, dynamic>(),
      );

      if (!signature.isComplete) {
        throw const VideoUploadException(
          'Upload authorization failed. Please try again.',
        );
      }

      return signature;
    } on FirebaseFunctionsException catch (error) {
      throw VideoUploadException(
        error.message ?? 'Could not authorize the upload.',
      );
    } on VideoUploadException {
      rethrow;
    } catch (error) {
      throw VideoUploadException('Could not authorize the upload: $error');
    }
  }

  Future<CloudinaryVideoAsset> upload({
    required File file,
    required VideoUploadSignature signature,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url =
        'https://api.cloudinary.com/v1_1/${signature.cloudName}/video/upload';

    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'api_key': signature.apiKey,
        'timestamp': '${signature.timestamp}',
        'signature': signature.signature,
        'folder': signature.folder,
        'public_id': signature.publicId,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 2),
          // A non-2xx must be inspected: Cloudinary explains signature errors
          // in the body rather than in the status alone.
          validateStatus: (_) => true,
        ),
      );

      final data = response.data ?? const <String, dynamic>{};
      final status = response.statusCode ?? 0;

      if (status == 401 ||
          '${data['error'] ?? ''}'.toLowerCase().contains('signature')) {
        throw VideoUploadException(
          '${data['error']?['message'] ?? 'Upload signature expired.'}',
          isSignatureProblem: true,
        );
      }

      if (status < 200 || status >= 300) {
        throw VideoUploadException(
          '${data['error']?['message'] ?? 'Upload failed ($status).'}',
        );
      }

      if (data['secure_url'] == null) {
        throw const VideoUploadException(
          'The upload did not return a video URL.',
        );
      }

      return CloudinaryVideoAsset.fromResponse(
        data,
        cloudName: signature.cloudName,
        fallbackPublicId: '${signature.folder}/${signature.publicId}',
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw const VideoUploadException(
          'Upload cancelled.',
          isSignatureProblem: false,
        );
      }
      throw VideoUploadException(
        error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.receiveTimeout
            ? 'The upload timed out. Check your connection and try again.'
            : 'Upload failed: ${error.message ?? 'network error'}',
      );
    }
  }

  /// Best-effort asset removal (cancel, or a post deleted while uploading).
  Future<bool> deleteAsset({
    required String assetId,
    required String trendId,
  }) async {
    try {
      await _functions.httpsCallable(deleteCallable).call({
        'assetId': assetId,
        'trendId': trendId,
      });
      return true;
    } catch (error) {
      debugPrint('Cloudinary asset delete failed: $error');
      return false;
    }
  }
}
