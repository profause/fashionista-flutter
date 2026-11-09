import 'package:fashionista/data/models/trends/bloc/video_editor_state.dart';
import 'package:fashionista/data/models/video/video_metadata.dart';
import 'package:fashionista/data/services/video/native_video_editor_engine.dart';
import 'package:fashionista/domain/video/video_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the trim/crop/mute selection and the single export pass.
class VideoEditorCubit extends Cubit<VideoEditorState> {
  VideoEditorCubit({VideoEngine? engine})
    : _engine = engine ?? NativeVideoEditorEngine(),
      super(const VideoEditorState());

  final VideoEngine _engine;

  String? _outputPath;
  bool _cancelled = false;

  static const int filmstripFrames = 8;

  /// Loads [path]; [aspect] is the framing the recorder was showing.
  Future<void> load(String path, {VideoAspectPreset? aspect}) async {
    emit(const VideoEditorState(stage: VideoEditorStage.loading));

    try {
      final metadata = await _engine.inspect(path);
      final initialEnd = metadata.duration > VideoEngine.maxDuration
          ? VideoEngine.maxDuration
          : metadata.duration;

      emit(
        VideoEditorState(
          stage: VideoEditorStage.ready,
          sourcePath: path,
          metadata: metadata,
          trimStart: Duration.zero,
          trimEnd: initialEnd,
          aspect: aspect ?? VideoAspectPreset.original,
        ),
      );

      await _buildFilmstrip(path, metadata.duration);
    } on VideoEngineException catch (error) {
      emit(state.copyWith(stage: VideoEditorStage.error, error: error.message));
    } catch (error) {
      emit(
        state.copyWith(
          stage: VideoEditorStage.error,
          error: 'That video could not be opened.',
        ),
      );
    }
  }

  /// Applies a new selection, keeping it inside the clip and the 30 s cap.
  void setTrim(Duration start, Duration end) {
    final metadata = state.metadata;
    if (metadata == null) return;

    var safeStart = _clamp(start, Duration.zero, metadata.duration);
    var safeEnd = _clamp(end, Duration.zero, metadata.duration);

    if (safeEnd <= safeStart) {
      safeEnd = safeStart + const Duration(seconds: 1);
    }

    if (safeEnd - safeStart > VideoEngine.maxDuration) {
      // Dragging the end past the cap pushes the start instead of refusing the
      // gesture, which is what every social editor does.
      safeStart = safeEnd - VideoEngine.maxDuration;
      if (safeStart < Duration.zero) {
        safeStart = Duration.zero;
        safeEnd = VideoEngine.maxDuration;
      }
    }

    emit(state.copyWith(trimStart: safeStart, trimEnd: safeEnd));
  }

  void setAspect(VideoAspectPreset preset) {
    emit(state.copyWith(aspect: preset));
  }

  void setMuted(bool muted) {
    emit(state.copyWith(muteAudio: muted));
  }

  void reset() {
    final metadata = state.metadata;
    if (metadata == null) return;

    emit(
      state.copyWith(
        aspect: VideoAspectPreset.original,
        muteAudio: false,
        trimStart: Duration.zero,
        trimEnd: metadata.duration > VideoEngine.maxDuration
            ? VideoEngine.maxDuration
            : metadata.duration,
        clearExported: true,
        progress: 0,
        stage: VideoEditorStage.ready,
      ),
    );
  }

  Future<void> export() async {
    final metadata = state.metadata;
    final source = state.sourcePath;
    if (metadata == null || source == null || state.isExporting) return;

    if (!state.canExport) {
      emit(
        state.copyWith(
          error: state.selection < VideoEngine.minDuration
              ? 'Select at least one second.'
              : 'Videos can be at most 30 seconds long.',
        ),
      );
      return;
    }

    _cancelled = false;
    emit(
      state.copyWith(
        stage: VideoEditorStage.exporting,
        progress: 0,
        clearError: true,
        clearExported: true,
      ),
    );

    try {
      final directory = await NativeVideoEditorEngine.ensureWorkspace();
      final outputPath =
          '${directory.path}/export_${DateTime.now().microsecondsSinceEpoch}.mp4';
      _outputPath = outputPath;

      final crop = _cropFor(metadata);

      final processed = await _engine.process(
        inputPath: source,
        outputPath: outputPath,
        start: state.trimStart,
        end: state.trimEnd,
        crop: crop,
        muteAudio: state.muteAudio,
        settings: VideoOutputSettings.defaults,
        onProgress: (value) {
          if (isClosed || _cancelled) return;
          emit(state.copyWith(progress: value.clamp(0, 1).toDouble()));
        },
      );

      if (_cancelled) return;

      emit(
        state.copyWith(
          stage: VideoEditorStage.exported,
          exported: processed,
          progress: 1,
        ),
      );
    } on VideoEngineException catch (error) {
      emit(state.copyWith(stage: VideoEditorStage.ready, error: error.message));
    } catch (error) {
      debugPrint('Export failed: $error');
      emit(
        state.copyWith(
          stage: VideoEditorStage.ready,
          error: 'The video could not be processed. Try a shorter clip.',
        ),
      );
    }
  }

  Future<void> cancelExport() async {
    _cancelled = true;
    final output = _outputPath;
    if (output != null) {
      try {
        await _engine.cancel(output);
      } catch (error) {
        debugPrint('Export cancel failed: $error');
      }
    }
    emit(state.copyWith(stage: VideoEditorStage.ready, progress: 0));
  }

  VideoCrop _cropFor(VideoMetadata metadata) {
    final aspect = state.aspect.aspect;
    if (aspect == null) return VideoCrop.original;

    return VideoCrop.centeredForAspect(
      targetAspect: aspect,
      sourceAspect: metadata.aspectRatio,
    );
  }

  Future<void> _buildFilmstrip(String path, Duration duration) async {
    if (duration <= Duration.zero) return;

    final thumbnails = <String>[];
    for (var i = 0; i < filmstripFrames; i++) {
      final at = Duration(
        milliseconds: (duration.inMilliseconds * (i / filmstripFrames)).round(),
      );

      try {
        thumbnails.add(await _engine.thumbnail(path, at: at));
      } catch (error) {
        debugPrint('Thumbnail $i failed: $error');
      }
    }

    if (isClosed || thumbnails.isEmpty) return;
    emit(state.copyWith(thumbnails: thumbnails));
  }

  static Duration _clamp(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
