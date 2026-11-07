import 'dart:io';

import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/video_editor_state.dart';
import 'package:flutter/material.dart';

/// Filmstrip plus the start/end handles.
class TrimTimeline extends StatelessWidget {
  final VideoEditorState state;
  final ValueChanged<RangeValues> onChanged;

  const TrimTimeline({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final metadata = state.metadata;
    if (metadata == null) return const SizedBox.shrink();

    final total = metadata.duration.inMilliseconds.toDouble();
    final maxSeconds = total <= 0 ? 1.0 : total / 1000;
    final start = state.trimStart.inMilliseconds / 1000;
    final end = state.trimEnd.inMilliseconds / 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (final thumb in state.thumbnails)
                  Expanded(
                    child: Image.file(
                      File(thumb),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: context.cardSurface),
                    ),
                  ),
                if (state.thumbnails.isEmpty)
                  Expanded(
                    child: Container(
                      color: context.cardSurface,
                      child: const Center(
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        RangeSlider(
          values: RangeValues(
            start.clamp(0, maxSeconds),
            end.clamp(0, maxSeconds),
          ),
          min: 0,
          max: maxSeconds,
          divisions: maxSeconds.round().clamp(1, 300),
          labels: RangeLabels('${start.round()}s', '${end.round()}s'),
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected ${state.durationLabel}',
              style: TextStyle(fontSize: 12, color: context.secondaryLabel),
            ),
            Text(
              'Max 30s',
              style: TextStyle(fontSize: 12, color: context.secondaryLabel),
            ),
          ],
        ),
      ],
    );
  }
}
