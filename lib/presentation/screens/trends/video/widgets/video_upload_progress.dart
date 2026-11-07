import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/video_upload_cubit.dart';
import 'package:fashionista/data/models/trends/bloc/video_upload_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modal progress for the signed upload, with cancel and retry in place.
///
/// Pops `true` when the post is published, so the composer can close itself.
class VideoUploadProgress extends StatefulWidget {
  const VideoUploadProgress({super.key});

  @override
  State<VideoUploadProgress> createState() => _VideoUploadProgressState();
}

class _VideoUploadProgressState extends State<VideoUploadProgress> {
  bool _closed = false;

  /// The upload can finish before this dialog mounts (a small file on a fast
  /// connection), so the listener alone is not enough.
  void _closeIfFinished(VideoUploadState state) {
    if (_closed || state.phase != VideoUploadPhase.completed) return;
    _closed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoUploadCubit, VideoUploadState>(
      listenWhen: (previous, current) =>
          current.phase == VideoUploadPhase.completed,
      listener: (context, state) => _closeIfFinished(state),
      builder: (context, state) {
        _closeIfFinished(state);
        final cubit = context.read<VideoUploadCubit>();
        final failed = state.phase == VideoUploadPhase.failed;

        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: context.cardSurface,
            title: Text(
              failed ? 'Upload problem' : 'Publishing video',
              style: const TextStyle(fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (failed) ...[
                  Text(
                    state.error ?? 'The upload failed.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.publishFailedOnly
                        ? 'The video is uploaded; only the post is missing.'
                        : 'Nothing was posted.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryLabel,
                    ),
                  ),
                ] else ...[
                  LinearProgressIndicator(
                    value:
                        state.phase == VideoUploadPhase.uploading &&
                            state.progress > 0
                        ? state.progress
                        : null,
                    color: context.accent,
                    backgroundColor: context.hairline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    switch (state.phase) {
                      VideoUploadPhase.authorizing => 'Authorizing upload…',
                      VideoUploadPhase.uploading =>
                        'Uploading ${(state.progress * 100).round()}%',
                      VideoUploadPhase.saving => 'Saving your post…',
                      _ => 'Preparing…',
                    },
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryLabel,
                    ),
                  ),
                ],
              ],
            ),
            actions: failed
                ? [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Close'),
                    ),
                    FilledButton(
                      onPressed: cubit.retry,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.accent,
                      ),
                      child: const Text('Retry'),
                    ),
                  ]
                : [
                    TextButton(
                      onPressed: cubit.cancel,
                      child: const Text('Cancel'),
                    ),
                  ],
          ),
        );
      },
    );
  }
}
