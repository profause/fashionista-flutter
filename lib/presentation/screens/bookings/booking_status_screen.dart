import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Step 3 of booking: the result of the submitted request.
class BookingStatusScreen extends StatelessWidget {
  final Booking booking;

  const BookingStatusScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = DateTime.tryParse(booking.date);

    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        foregroundColor: context.onCanvasText,
        backgroundColor: context.canvasBackground,
        title: Text('Booking request', style: textTheme.titleMedium),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: context.hairline)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 34,
                color: context.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Request sent',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your appointment is pending confirmation from the designer.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: context.secondaryLabel,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.hairline),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        date == null
                            ? booking.date
                            : DateFormat('EEEE, d MMMM yyyy').format(date),
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
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: context.secondaryLabel,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${TimeOfDayX.toDisplay(booking.startTime)} - '
                      '${TimeOfDayX.toDisplay(booking.endTime)}',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      booking.notes!,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: context.secondaryLabel,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil(
              (route) => route.isFirst,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
