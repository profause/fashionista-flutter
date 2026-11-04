import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:flutter/material.dart';

class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusChip({super.key, required this.status});

  Color _color(BuildContext context) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange.shade700;
      case BookingStatus.confirmed:
        return Colors.green.shade700;
      case BookingStatus.declined:
        return Colors.red.shade700;
      case BookingStatus.cancelled:
        return context.secondaryLabel;
      case BookingStatus.completed:
        return context.accent;
      case BookingStatus.noShow:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
