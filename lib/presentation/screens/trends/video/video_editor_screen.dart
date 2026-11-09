import 'dart:io';

import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/video_editor_cubit.dart';
import 'package:fashionista/data/models/trends/bloc/video_editor_state.dart';
import 'package:fashionista/data/models/video/edited_video.dart';
import 'package:fashionista/presentation/screens/trends/video/widgets/trim_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

/// Trim, crop and mute a clip, then export it. Pops with an [EditedVideo].
class VideoEditorScreen extends StatelessWidget {
  final String sourcePath;

  /// Framing chosen in the recorder; the editor opens on that crop.
  final VideoAspectPreset? initialAspect;

  const VideoEditorScreen({
    super.key,
    required this.sourcePath,
    this.initialAspect,
  });

  static Future<EditedVideo?> open(
    BuildContext context,
    String path, {
    VideoAspectPreset? aspect,
  }) {
    return Navigator.of(context).push<EditedVideo>(
      MaterialPageRoute(
        builder: (_) =>
            VideoEditorScreen(sourcePath: path, initialAspect: aspect),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          VideoEditorCubit()..load(sourcePath, aspect: initialAspect),
      child: const _VideoEditorView(),
    );
  }
}

class _VideoEditorView extends StatelessWidget {
  const _VideoEditorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        backgroundColor: context.canvasBackground,
        foregroundColor: context.onCanvasText,
        elevation: 0,
        title: const Text('Edit video'),
      ),
      body: BlocConsumer<VideoEditorCubit, VideoEditorState>(
        listenWhen: (previous, current) =>
            current.stage == VideoEditorStage.exported,
        listener: (context, state) {
          final exported = state.exported;
          if (exported == null) return;
          Navigator.of(context).pop(EditedVideo.fromProcessed(exported));
        },
        builder: (context, state) {
          if (state.stage == VideoEditorStage.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.stage == VideoEditorStage.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  state.error ?? 'That video could not be opened.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final cubit = context.read<VideoEditorCubit>();

          return Column(
            children: [
              Expanded(
                child: _Preview(
                  path: state.sourcePath!,
                  metadataWidth: state.metadata?.width ?? 0,
                  metadataHeight: state.metadata?.height ?? 0,
                  aspect: state.aspect.aspect,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    TrimTimeline(
                      state: state,
                      onChanged: (values) => cubit.setTrim(
                        Duration(milliseconds: (values.start * 1000).round()),
                        Duration(milliseconds: (values.end * 1000).round()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AspectRow(state: state),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: state.muteAudio,
                      onChanged: cubit.setMuted,
                      title: const Text(
                        'Mute audio',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        state.muteAudio
                            ? 'The exported video will have no sound'
                            : 'Original audio is kept',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.isExporting)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: state.progress == 0 ? null : state.progress,
                            color: context.accent,
                            backgroundColor: context.hairline,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Processing ${(state.progress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.secondaryLabel,
                                ),
                              ),
                              TextButton(
                                onPressed: cubit.cancelExport,
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          TextButton(
                            onPressed: cubit.reset,
                            child: const Text('Reset'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: state.canExport ? cubit.export : null,
                            style: TextButton.styleFrom(
                              foregroundColor: context.accent,
                            ),
                            child: Text('Next'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AspectRow extends StatelessWidget {
  final VideoEditorState state;

  const _AspectRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoEditorCubit>();

    return Wrap(
      spacing: 8,
      children: [
        for (final preset in VideoAspectPreset.values)
          ChoiceChip(
            label: Text(preset.label, style: const TextStyle(fontSize: 12)),
            selected: state.aspect == preset,
            onSelected: (_) => cubit.setAspect(preset),
          ),
      ],
    );
  }
}

/// Local preview of the clip, sized to the chosen crop.
class _Preview extends StatefulWidget {
  final String path;
  final int metadataWidth;
  final int metadataHeight;
  final double? aspect;

  const _Preview({
    required this.path,
    required this.metadataWidth,
    required this.metadataHeight,
    required this.aspect,
  });

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final file = File(widget.path);
    if (!await file.exists()) return;

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cropAspect =
        widget.aspect ??
        (widget.metadataHeight == 0
            ? controller.value.aspectRatio
            : widget.metadataWidth / widget.metadataHeight);

    return Center(
      child: GestureDetector(
        onTap: () async {
          if (controller.value.isPlaying) {
            await controller.pause();
          } else {
            await controller.play();
          }
          if (mounted) {
            setState(() => _playing = controller.value.isPlaying);
          }
        },
        child: AspectRatio(
          aspectRatio: cropAspect,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              if (!_playing)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
