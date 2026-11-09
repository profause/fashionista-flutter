import 'package:camera/camera.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/video_capture_cubit.dart';
import 'package:fashionista/data/models/trends/bloc/video_capture_state.dart';
import 'package:fashionista/data/models/trends/bloc/video_editor_state.dart';
import 'package:fashionista/data/models/video/edited_video.dart';
import 'package:fashionista/presentation/screens/trends/video/video_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen recorder. Pops with the edited clip.
///
/// Stopping the recording opens the editor straight away: recording and editing
/// are one flow, so there is no separate "keep this take?" step.
class VideoCaptureScreen extends StatelessWidget {
  /// Injected by tests; the real screen owns its cubit (and its camera).
  final VideoCaptureCubit? cubit;

  const VideoCaptureScreen({super.key, this.cubit});

  static Future<EditedVideo?> open(BuildContext context) {
    return Navigator.of(context).push<EditedVideo>(
      MaterialPageRoute(builder: (_) => const VideoCaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final injected = cubit;
    if (injected != null) {
      return BlocProvider<VideoCaptureCubit>.value(
        value: injected,
        child: const _VideoCaptureView(),
      );
    }

    return BlocProvider(
      create: (_) => VideoCaptureCubit()..initialize(),
      child: const _VideoCaptureView(),
    );
  }
}

class _VideoCaptureView extends StatefulWidget {
  const _VideoCaptureView();

  @override
  State<_VideoCaptureView> createState() => _VideoCaptureViewState();
}

class _VideoCaptureViewState extends State<_VideoCaptureView> {
  /// Guards against a second editor while one is already on top.
  bool _editorOpen = false;

  /// Set when the user dismisses the recorder, so a recording that is stopped on
  /// the way out cannot reopen the editor behind the popped route.
  bool _closing = false;

  /// The clip the editor was opened for, so a cancelled edit does not reopen it
  /// on the next rebuild.
  String? _openedFor;

  Future<void> _openEditor(String path) async {
    if (_editorOpen || _closing) return;
    _editorOpen = true;

    final aspect = context.read<VideoCaptureCubit>().state.aspect;
    final edited = await VideoEditorScreen.open(context, path, aspect: aspect);

    _editorOpen = false;
    if (!mounted) return;

    // Cancelling the edit keeps the take: the recorder is still behind the
    // editor, showing Retake / Edit.
    if (edited != null) Navigator.of(context).pop(edited);
  }

  Future<void> _close() async {
    _closing = true;

    final cubit = context.read<VideoCaptureCubit>();
    if (cubit.state.isRecording) await cubit.stopRecording();
    if (mounted) Navigator.of(context).pop();
  }

  void _onState(VideoCaptureState state) {
    final path = state.recordedPath;
    if (state.stage != VideoCaptureStage.recorded || path == null) return;
    if (_openedFor == path) return;

    _openedFor = path;
    // A listener can fire while a frame is being built; navigate afterwards.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _openedFor == path) _openEditor(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<VideoCaptureCubit, VideoCaptureState>(
        listener: (context, state) => _onState(state),
        builder: (context, state) {
          // The preview runs under the status bar and the notch; only the
          // controls respect the safe area, otherwise the viewfinder is inset
          // by black bands at the top and bottom.
          return Stack(
            children: [
              Positioned.fill(child: _Preview(state: state)),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _TopBar(state: state, onClose: _close),
                      if (state.isRecording) _RecordingBadge(state: state),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: _BottomBar(state: state, onEdit: _openEditor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final VideoCaptureState state;

  const _Preview({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoCaptureCubit>();
    final controller = cubit.controller;

    if (state.stage == VideoCaptureStage.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                state.error ?? 'The camera could not be used.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: cubit.initialize,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // The frame *is* the crop: what fits inside this box is what the editor
    // exports, because both use the same centred ratio.
    final aspect = state.aspect.aspect ?? _nativePortraitRatio(controller);

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: _FullScreenPreview(controller: controller),
        ),
      ),
    );
  }

  /// Portrait ratio of the camera stream, used when the framing is "original".
  double _nativePortraitRatio(CameraController controller) {
    final ratio = controller.value.aspectRatio;
    if (ratio.isNaN || ratio <= 0) return 9 / 16;

    return const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ].contains(controller.value.deviceOrientation)
        ? ratio
        : 1 / ratio;
  }
}

/// Camera preview that covers its framing box instead of letterboxing inside it.
///
/// [CameraPreview] already applies its own `AspectRatio`, inverted in portrait
/// (`1 / value.aspectRatio`) — wrapping it in a second, un-inverted one made the
/// viewfinder shrink to a letterboxed rectangle. Here the preview is laid out at
/// its native ratio and scaled with `BoxFit.cover`, which is what a viewfinder
/// should do: fill the frame, crop the overhang.
class _FullScreenPreview extends StatelessWidget {
  final CameraController controller;

  const _FullScreenPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mirrors CameraPreview's own orientation rule so the cover box and the
    // widget's internal AspectRatio agree.
    final isLandscape = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ].contains(controller.value.deviceOrientation);

    final ratio = isLandscape
        ? controller.value.aspectRatio
        : 1 / controller.value.aspectRatio;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            // Any size with the preview's ratio works: BoxFit.cover scales it.
            width: 1080,
            height: 1080 / ratio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VideoCaptureState state;
  final Future<void> Function() onClose;

  const _TopBar({required this.state, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoCaptureCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cancel',
          ),
          const Spacer(),
          if (state.isMuted)
            const Tooltip(
              message: 'Microphone is off — recording will be silent',
              child: Icon(Icons.mic_off, color: Colors.white70, size: 20),
            ),
          const SizedBox(width: 8),
          if (state.isTorchAvailable && !state.isFrontCamera)
            IconButton(
              onPressed: cubit.toggleTorch,
              icon: Icon(
                state.isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: state.isTorchOn ? context.accent : Colors.white,
              ),
              tooltip: state.isTorchOn
                  ? 'Turn the light off'
                  : 'Turn the light on',
            ),
          if (state.cameraCount > 1)
            IconButton(
              onPressed: state.isRecording ? null : cubit.switchCamera,
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              tooltip: 'Switch camera',
            ),
        ],
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  final VideoCaptureState state;

  const _RecordingBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fiber_manual_record,
                color: Colors.red,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                state.remainingLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VideoCaptureState state;

  /// Opens the editor for [state.recordedPath]; shared with the gallery path so
  /// both sources land in the same flow.
  final Future<void> Function(String path) onEdit;

  const _BottomBar({required this.state, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoCaptureCubit>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          if (state.stage != VideoCaptureStage.recorded) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AspectSelector(
                selected: state.aspect,
                enabled: !state.isRecording,
                onSelect: cubit.setAspect,
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (state.stage != VideoCaptureStage.recorded) ...[
                IconButton(
                  onPressed: state.isRecording
                      ? null
                      : () async {
                          final path = await cubit.pickFromGallery();
                          if (!context.mounted) return;
                          if (path != null) await onEdit(path);
                        },
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Choose from gallery',
                ),
              ],
              if (state.stage == VideoCaptureStage.recorded) ...[
                const SizedBox(width: 16),
                IconButton(
                  onPressed: cubit.retake,
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
              GestureDetector(
                onTap: state.isRecording
                    ? cubit.stopRecording
                    : cubit.startRecording,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: state.isRecording ? 28 : 58,
                      height: state.isRecording ? 28 : 58,
                      decoration: BoxDecoration(
                        color: state.isRecording ? Colors.red : context.accent,
                        borderRadius: BorderRadius.circular(
                          state.isRecording ? 6 : 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Second spacer keeps the record button centred.
              if (state.stage == VideoCaptureStage.recorded) ...[
                IconButton(
                  onPressed: () {
                    final path = state.recordedPath;
                    if (path != null) onEdit(path);
                  },
                  icon: Icon(
                    Icons.check_circle,
                    color: context.accent,
                    size: 32,
                  ),
                ),
              ],
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ratio chips above the shutter: what you frame is what gets exported.
class _AspectSelector extends StatelessWidget {
  /// 9:16 first would read as "no choice"; the alternatives lead.
  static const List<VideoAspectPreset> presets = [
    VideoAspectPreset.square,
    VideoAspectPreset.portraitFourFive,
    VideoAspectPreset.portrait,
  ];

  final VideoAspectPreset selected;
  final bool enabled;
  final ValueChanged<VideoAspectPreset> onSelect;

  const _AspectSelector({
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final preset in presets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _AspectChip(
              preset: preset,
              isSelected: preset == selected,
              onTap: enabled ? () => onSelect(preset) : null,
            ),
          ),
      ],
    );
  }
}

class _AspectChip extends StatelessWidget {
  final VideoAspectPreset preset;
  final bool isSelected;
  final VoidCallback? onTap;

  const _AspectChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.accent : Colors.white70;

    return Material(
      color: Colors.black.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? context.accent : Colors.white24,
            ),
          ),
          child: Text(
            preset.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
