import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:flutter/material.dart';

/// Editable row for a single availability session.
class SessionEditorTile extends StatelessWidget {
  final AvailabilitySession session;
  final ValueChanged<AvailabilitySession> onChanged;
  final VoidCallback onDelete;

  const SessionEditorTile({
    super.key,
    required this.session,
    required this.onChanged,
    required this.onDelete,
  });

  Future<void> _pick(
    BuildContext context, {
    required bool isStart,
  }) async {
    final initial = TimeOfDayX.toTimeOfDay(
          isStart ? session.startTime : session.endTime,
        ) ??
        const TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: isStart ? 'Session start' : 'Session end',
    );

    if (picked == null) return;
    final value = TimeOfDayX.fromTimeOfDay(picked);

    onChanged(
      isStart
          ? session.copyWith(startTime: value)
          : session.copyWith(endTime: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.iconSubstrate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimeField(
              label: 'From',
              value: TimeOfDayX.toDisplay(session.startTime),
              onTap: () => _pick(context, isStart: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward,
              size: 16,
              color: context.secondaryLabel,
            ),
          ),
          Expanded(
            child: _TimeField(
              label: 'To',
              value: TimeOfDayX.toDisplay(session.endTime),
              onTap: () => _pick(context, isStart: false),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: textTheme.bodySmall?.color ?? context.secondaryLabel,
            ),
            tooltip: 'Remove session',
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: context.secondaryLabel,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
