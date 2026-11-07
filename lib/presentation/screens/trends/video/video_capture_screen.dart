import 'package:camera/camera.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/video_capture_cubit.dart';
import 'package:fashionista/data/models/trends/bloc/video_capture_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen recorder. Pops with the recorded or picked file path.
class VideoCaptureScreen extends StatelessWidget {
  const VideoCaptureScreen({super.key});

  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const VideoCaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoCaptureCubit()..initialize(),
      child: const _VideoCaptureView(),
    );
  }
}

class _VideoCaptureView extends StatelessWidget {
  const _VideoCaptureView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<VideoCaptureCubit, VideoCaptureState>(
        listener: (context, state) {
          if (state.stage == VideoCaptureStage.error &&
              state.error != null &&
              state.recordedPath == null) {
            // Keep the message on screen; the user can retry from the retry
            // button instead of losing the screen.
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _Preview(state: state)),
                _TopBar(state: state),
                if (state.isRecording) _RecordingBadge(state: state),
                _BottomBar(state: state),
              ],
            ),
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

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VideoCaptureState state;

  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoCaptureCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (state.isRecording) await cubit.stopRecording();
              if (context.mounted) Navigator.of(context).pop();
            },
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
    return Positioned(
      top: 56,
      left: 0,
      right: 0,
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

  const _BottomBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoCaptureCubit>();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Column(
        children: [
          if (state.stage == VideoCaptureStage.recorded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cubit.retake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(state.recordedPath),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.accent,
                      ),
                      child: Text('Edit ${state.elapsed.inSeconds}s clip'),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: state.isRecording
                      ? null
                      : () async {
                          final path = await cubit.pickFromGallery();
                          if (!context.mounted) return;
                          if (path != null) Navigator.of(context).pop(path);
                        },
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Choose from gallery',
                ),
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
                          color: state.isRecording
                              ? Colors.red
                              : context.accent,
                          borderRadius: BorderRadius.circular(
                            state.isRecording ? 6 : 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Second spacer keeps the record button centred.
                const SizedBox(width: 48),
              ],
            ),
        ],
      ),
    );
  }
}
