import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/data/models/video/video_upload_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Thrown for anything the user can act on (network, configuration, rejection).
class VideoUploadException implements Exception {
  final String message;

  const VideoUploadException(this.message);

  @override
  String toString() => message;
}

/// Unsigned Cloudinary video uploads.
///
/// Authorization comes from a public upload preset, so no API key or signature
/// is involved and nothing has to be signed server-side (plan §19). Deletion
/// prefers the `delete_token` Cloudinary returns at upload time; the
/// `deleteCloudinaryAsset` callable remains as the post-10-minute fallback.
class FirebaseVideoUploadService {
  FirebaseVideoUploadService({
    Dio? dio,
    FirebaseFunctions? functions,
    VideoUploadConfig? config,
    String? Function()? currentUserId,
  }) : _dio = dio ?? Dio(),
       _providedFunctions = functions,
       _providedConfig = config,
       _currentUserId = currentUserId;

  static const String deleteCallable = 'deleteCloudinaryAsset';
  static const String defaultUploadPreset = 'ml_default';
  static const String defaultBaseFolder = 'fashionista';

  final Dio _dio;
  final FirebaseFunctions? _providedFunctions;
  final VideoUploadConfig? _providedConfig;
  final String? Function()? _currentUserId;

  VideoUploadConfig? _config;

  /// Resolved on first use, never in the constructor: this service is built by
  /// the service locator *before* `Firebase.initializeApp()`, and touching
  /// `FirebaseFunctions.instance` there throws `[core/no-app]`.
  FirebaseFunctions get _functions =>
      _providedFunctions ?? FirebaseFunctions.instance;

  /// Remote-config values, read lazily for the same reason as [_functions] —
  /// Remote Config is not initialized when the locator runs.
  VideoUploadConfig get _uploadConfig => _config ??= _resolveConfig();

  VideoUploadConfig _resolveConfig() {
    final provided = _providedConfig;
    if (provided != null) return provided;

    String read(String key) {
      try {
        return '${appConfig.get(key) ?? ''}'.trim();
      } catch (error) {
        debugPrint('Cloudinary config "$key" unavailable: $error');
        return '';
      }
    }

    // `cloudinary_url` is cloudinary://<api_key>:<secret>@<cloud_name>; only the
    // host is used here, so the credentials never leave the config.
    final cloudName = Uri.tryParse(read('cloudinary_url'))?.host ?? '';
    final preset = read('cloudinary_video_upload_preset');
    // Reuses the base folder the image uploads already use, so the client and
    // the delete callable agree on `fashionista/trends/videos/<uid>`.
    final folder = read('cloudinary_base_folder');

    return VideoUploadConfig(
      cloudName: cloudName,
      uploadPreset: preset.isEmpty ? defaultUploadPreset : preset,
      baseFolder: folder.isEmpty ? defaultBaseFolder : folder,
    );
  }

  String? _userId() {
    try {
      return (_currentUserId ?? () => FirebaseAuth.instance.currentUser?.uid)();
    } catch (error) {
      debugPrint('Cloudinary upload: no signed-in user ($error)');
      return null;
    }
  }

  /// Uploads [file] with the unsigned preset and returns the asset description.
  Future<CloudinaryVideoAsset> upload({
    required File file,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final config = _uploadConfig;
    if (!config.isComplete) {
      throw const VideoUploadException(
        'Video uploads are not configured. Please try again later.',
      );
    }

    final userId = _userId();
    if (userId == null || userId.isEmpty) {
      throw const VideoUploadException('Sign in again to upload a video.');
    }

    final folder = config.folderFor(userId);
    // Unsigned uploads never overwrite, so a unique public id keeps a retry from
    // colliding with an earlier attempt.
    final publicId = const Uuid().v4();
    final url =
        'https://api.cloudinary.com/v1_1/${config.cloudName}/video/upload';

    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'upload_preset': config.uploadPreset,
        'folder': folder,
        'public_id': publicId,
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
          // A non-2xx must be inspected: Cloudinary explains preset and
          // parameter errors in the body rather than in the status alone.
          validateStatus: (_) => true,
        ),
      );

      final data = response.data ?? const <String, dynamic>{};
      final status = response.statusCode ?? 0;

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
        cloudName: config.cloudName,
        fallbackPublicId: '$folder/$publicId',
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw const VideoUploadException('Upload cancelled.');
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

  /// Deletes a just-uploaded asset with its Cloudinary delete token.
  ///
  /// Cloudinary honours the token for 10 minutes after the upload; afterwards
  /// use [deleteAsset], which needs the backend.
  Future<bool> deleteByToken(String deleteToken) async {
    final cloudName = _uploadConfig.cloudName;
    if (deleteToken.isEmpty || cloudName.isEmpty) return false;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$cloudName/delete_by_token',
        data: {'token': deleteToken},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (_) => true,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) return true;

      debugPrint(
        'Cloudinary token delete failed ($status): '
        '${response.data?['result']}',
      );
      return false;
    } catch (error) {
      debugPrint('Cloudinary token delete failed: $error');
      return false;
    }
  }

  /// Best-effort asset removal through the Admin API (needs the API secret).
  ///
  /// The only way to delete an asset once its delete token has expired.
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
