import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:flutter/material.dart';

/// Explains which existing appointments would fall outside the new schedule.
///
/// Returning `true` means "save anyway"; bookings are never cancelled or
/// deleted by the app.
Future<bool> showAvailabilityConflictDialog(
  BuildContext context,
  List<Booking> conflicts,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: dialogContext.cardSurface,
        title: const Text('Appointments affected'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These existing appointments fall outside the new schedule:',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: conflicts.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 12,
                    color: dialogContext.hairline,
                  ),
                  itemBuilder: (_, index) {
                    final booking = conflicts[index];
                    return Row(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 18,
                          color: dialogContext.secondaryLabel,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${booking.date} · '
                            '${TimeOfDayX.toDisplay(booking.startTime)} - '
                            '${TimeOfDayX.toDisplay(booking.endTime)} '
                            '(${booking.status.label})',
                            style: Theme.of(
                              dialogContext,
                            ).textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Existing bookings are kept. Review them first if you need to '
                'reschedule or cancel.',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: dialogContext.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save anyway'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
