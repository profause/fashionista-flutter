import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:flutter/material.dart';

/// Read-only preview of the slots generated for one day.
class SlotPreviewGrid extends StatelessWidget {
  final List<AvailableSlot> slots;
  final String emptyMessage;

  const SlotPreviewGrid({
    super.key,
    required this.slots,
    this.emptyMessage = 'No slots generated for this configuration.',
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: context.iconSubstrate,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emptyMessage,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: context.secondaryLabel,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: slots.map((slot) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.iconSubstrate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                TimeOfDayX.toDisplay(slot.startTime),
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          '${slots.length} appointment${slots.length == 1 ? '' : 's'} available',
          style: textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: context.secondaryLabel,
          ),
        ),
      ],
    );
  }
}
