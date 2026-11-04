import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/booking_policy.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_bloc.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Booking summary plus the actions allowed for the current actor.
class BookingDetailsSheet extends StatelessWidget {
  final Booking booking;
  final String actorUserId;
  final bool actorIsDesigner;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
    required this.actorUserId,
    required this.actorIsDesigner,
  });

  Future<bool> showConfirmation(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.cardSurface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _change(BuildContext context, BookingStatus status) {
    context.read<BookingBloc>().add(
      ChangeBookingStatus(
        bookingId: booking.uid ?? '',
        status: status,
        actorUserId: actorUserId,
        actorIsDesigner: actorIsDesigner,
      ),
    );
    Navigator.of(context).pop();
  }

  bool _clientCanCancel(Booking booking) {
    if (booking.status == BookingStatus.pending) return true;
    if (booking.status != BookingStatus.confirmed) return false;
    final startAt = booking.startAt;
    if (startAt == null) return true;
    return DateTime.now().toUtc().isBefore(
      startAt.subtract(BookingPolicy.clientCancellationCutoff),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = DateTime.tryParse(booking.date);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.hairline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? booking.date
                        : DateFormat('EEE, d MMM yyyy').format(date),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: context.secondaryLabel),
                const SizedBox(width: 6),
                Text(
                  '${TimeOfDayX.toDisplay(booking.startTime)} - '
                  '${TimeOfDayX.toDisplay(booking.endTime)} '
                  '(${booking.durationMinutes} min)',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
              ],
            ),
            if (booking.timezone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.public, size: 14, color: context.secondaryLabel),
                  const SizedBox(width: 6),
                  Text(
                    booking.timezone,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: context.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ],
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.iconSubstrate,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  booking.notes!,
                  style: textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ..._actions(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    if (actorIsDesigner) {
      switch (booking.status) {
        case BookingStatus.pending:
          return [
            FilledButton(
              onPressed: () => _change(context, BookingStatus.confirmed),
              style: FilledButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirm booking'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _change(context, BookingStatus.declined),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(color: context.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Decline'),
            ),
          ];
        case BookingStatus.confirmed:
          return [
            FilledButton(
              onPressed: () => _change(context, BookingStatus.completed),
              style: FilledButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Mark completed'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _change(context, BookingStatus.noShow),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.onCanvasText,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(color: context.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Mark no show'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _change(context, BookingStatus.cancelled),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(color: context.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel booking'),
            ),
          ];
        default:
          return [
            Text(
              'No further action needed for this booking.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: context.secondaryLabel,
              ),
            ),
          ];
      }
    }

    final canCancel = _clientCanCancel(booking);
    if (!canCancel) {
      return [
        Text(
          booking.status == BookingStatus.confirmed
              ? 'This appointment can no longer be cancelled online. '
                    'Please contact the designer.'
              : 'This booking cannot be cancelled.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: context.secondaryLabel,
          ),
        ),
      ];
    }

    return [
      OutlinedButton(
        onPressed: () async {
          final confirmed = await showConfirmation(
            context,
            'Cancel booking',
            'This releases your appointment slot. You can book again if a slot '
                'is still available.',
          );
          if (!confirmed || !context.mounted) return;
          _change(context, BookingStatus.cancelled);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          minimumSize: const Size.fromHeight(46),
          side: BorderSide(color: context.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Cancel booking'),
      ),
    ];
  }
}
