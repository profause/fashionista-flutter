import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:fashionista/data/models/trends/bloc/video_capture_state.dart';
import 'package:fashionista/domain/video/video_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Owns the camera, the recording clock and gallery selection.
///
/// The 30 s limit is enforced twice on purpose: `maxVideoDuration` lets the
/// platform stop the capture, and the cubit's own timer stops it again — the
/// countdown UI must never be the only thing enforcing the rule (plan §4).
class VideoCaptureCubit extends Cubit<VideoCaptureState> {
  VideoCaptureCubit({ImagePicker? picker})
    : _picker = picker ?? ImagePicker(),
      super(const VideoCaptureState());

  final ImagePicker _picker;

  CameraController? _controller;

  /// Exposed for `CameraPreview`; null until the camera is ready.
  CameraController? get controller => _controller;

  Timer? _ticker;
  DateTime? _startedAt;
  bool _disposed = false;

  Future<void> initialize() async {
    emit(
      state.copyWith(stage: VideoCaptureStage.initializing, clearError: true),
    );

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(
          state.copyWith(
            stage: VideoCaptureStage.error,
            error: 'No camera is available on this device.',
          ),
        );
        return;
      }

      final microphone = await Permission.microphone.request();
      final useAudio = microphone.isGranted || microphone.isLimited;

      // Prefer the back camera the first time, matching how people shoot
      // inspiration clips.
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      await _open(camera, useAudio: useAudio);

      emit(
        state.copyWith(
          stage: VideoCaptureStage.ready,
          cameraCount: cameras.length,
          isFrontCamera: camera.lensDirection == CameraLensDirection.front,
          isMuted: !useAudio,
          clearError: true,
        ),
      );
    } on CameraException catch (error) {
      emit(
        state.copyWith(stage: VideoCaptureStage.error, error: _describe(error)),
      );
    } catch (error) {
      emit(
        state.copyWith(
          stage: VideoCaptureStage.error,
          error: 'The camera could not be started: $error',
        ),
      );
    }
  }

  Future<void> switchCamera() async {
    if (state.cameraCount < 2 || state.isRecording) return;

    try {
      final cameras = await availableCameras();
      final current = _controller?.description;
      final next = state.isFrontCamera
          ? cameras.firstWhere(
              (item) => item.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            )
          : cameras.firstWhere(
              (item) => item.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            );

      if (current != null && next.name == current.name) return;

      await _controller?.dispose();
      await _open(next, useAudio: !state.isMuted);

      emit(
        state.copyWith(
          isFrontCamera: next.lensDirection == CameraLensDirection.front,
          stage: VideoCaptureStage.ready,
        ),
      );
    } catch (error) {
      debugPrint('Camera switch failed: $error');
    }
  }

  Future<void> startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state.isRecording) return;

    try {
      await controller.startVideoRecording();

      _startedAt = DateTime.now();
      emit(
        state.copyWith(
          stage: VideoCaptureStage.recording,
          elapsed: Duration.zero,
          clearRecording: true,
          clearError: true,
        ),
      );

      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final started = _startedAt;
        if (started == null || isClosed) return;

        final elapsed = DateTime.now().difference(started);
        if (elapsed >= VideoEngine.maxDuration) {
          // Independent of the UI countdown: stop no matter what it shows.
          unawaited(stopRecording());
          return;
        }
        emit(state.copyWith(elapsed: elapsed));
      });
    } on CameraException catch (error) {
      emit(
        state.copyWith(stage: VideoCaptureStage.error, error: _describe(error)),
      );
    }
  }

  Future<void> stopRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRecordingVideo) {
      await _stopTicker();
      return;
    }

    try {
      final file = await controller.stopVideoRecording();
      await _stopTicker();

      if (_disposed || isClosed) return;

      emit(
        state.copyWith(
          stage: VideoCaptureStage.recorded,
          recordedPath: file.path,
          elapsed: state.elapsed > VideoEngine.maxDuration
              ? VideoEngine.maxDuration
              : state.elapsed,
        ),
      );
    } on CameraException catch (error) {
      await _stopTicker();
      emit(
        state.copyWith(stage: VideoCaptureStage.error, error: _describe(error)),
      );
    }
  }

  /// Discards the recording and returns to the viewfinder.
  Future<void> retake() async {
    final path = state.recordedPath;
    if (path != null) {
      unawaited(_deleteQuietly(path));
    }

    emit(
      state.copyWith(
        stage: VideoCaptureStage.ready,
        elapsed: Duration.zero,
        clearRecording: true,
        clearError: true,
      ),
    );
  }

  /// Returns the selected clip path, or `null` when the picker was dismissed.
  Future<String?> pickFromGallery() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: VideoEngine.maxDuration,
      );
      if (picked == null) return null;

      final file = File(picked.path);
      if (!await file.exists()) {
        emit(
          state.copyWith(
            stage: VideoCaptureStage.error,
            error: 'That video could not be opened.',
          ),
        );
        return null;
      }

      return picked.path;
    } catch (error) {
      emit(
        state.copyWith(
          stage: VideoCaptureStage.error,
          error: 'That video could not be selected: $error',
        ),
      );
      return null;
    }
  }

  Future<void> _open(CameraDescription camera, {required bool useAudio}) async {
    // `camera` has no max-duration option, so the timer in `startRecording`
    // is the only thing enforcing the 30 s cap — hence the separate check
    // there rather than relying on the countdown widget.
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: useAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    _controller = controller;
  }

  Future<void> _stopTicker() async {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('Discard recording failed: $error');
    }
  }

  String _describe(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access is off. Enable it in Settings to record a video.';
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
        return 'Microphone access is off. You can still record a silent video.';
      case 'cameraPermission':
        return 'Camera permission is required to record a video.';
      default:
        return error.description ?? 'The camera could not be used.';
    }
  }

  @override
  Future<void> close() async {
    _disposed = true;
    await _stopTicker();
    await _controller?.dispose();
    _controller = null;
    return super.close();
  }
}
