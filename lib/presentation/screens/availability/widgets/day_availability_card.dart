import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:flutter/material.dart';

/// One weekday row on the manage-availability screen.
class DayAvailabilityCard extends StatelessWidget {
  final DesignerAvailability day;
  final VoidCallback onConfigure;
  final ValueChanged<bool> onToggle;

  const DayAvailabilityCard({
    super.key,
    required this.day,
    required this.onConfigure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = day.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onConfigure,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.dayName,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          enabled ? 'Enabled' : 'Unavailable',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: enabled
                                ? context.accent
                                : context.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    activeThumbColor: context.accent,
                    onChanged: onToggle,
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 4),
                Text(
                  'Duration: ${day.appointmentDurationMinutes} minutes',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: context.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 6),
                if (day.sessions.isEmpty)
                  Text(
                    'No sessions yet',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: context.secondaryLabel,
                    ),
                  )
                else
                  ..._sessionRows(context, textTheme),
                const SizedBox(height: 6),
                _PreviewLine(day: day),
              ] else ...[
                const SizedBox(height: 2),
                Text(
                  'No appointments can be booked on ${day.dayName}.',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: context.secondaryLabel,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    enabled ? 'Edit sessions' : 'Configure',
                    style: textTheme.labelMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.accent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 18, color: context.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sessionRows(BuildContext context, TextTheme textTheme) {
    return day.sessions.map((session) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: context.secondaryLabel,
            ),
            const SizedBox(width: 6),
            Text(
              '${TimeOfDayX.toDisplay(session.startTime)} - '
              '${TimeOfDayX.toDisplay(session.endTime)}',
              style: textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _PreviewLine extends StatelessWidget {
  final DesignerAvailability day;

  const _PreviewLine({required this.day});

  @override
  Widget build(BuildContext context) {
    if (day.sessions.isEmpty || day.appointmentDurationMinutes <= 0) {
      return const SizedBox.shrink();
    }

    final slots = SlotSchedulingService.generateSlots(
      sessions: day.sessions,
      durationMinutes: day.appointmentDurationMinutes,
    );

    if (slots.isEmpty) return const SizedBox.shrink();

    return Text(
      '${slots.length} slot${slots.length == 1 ? '' : 's'} generated',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12,
        color: context.secondaryLabel,
      ),
    );
  }
}

/// Small summary line used by the designer profile card.
class AvailabilitySummary extends StatelessWidget {
  final List<DesignerAvailability> weekly;

  const AvailabilitySummary({super.key, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final enabledDays = weekly.where((day) => day.isAvailable).length;
    return Text(
      enabledDays == 0
          ? 'No working days configured'
          : '$enabledDays working day${enabledDays == 1 ? '' : 's'} configured',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
