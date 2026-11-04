import 'package:equatable/equatable.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';

/// One bookable appointment window generated from a designer's availability.
///
/// Slots are never persisted: they are derived from sessions + duration and
/// then filtered against existing bookings.
class AvailableSlot extends Equatable {
  /// Session start in `HH:mm`.
  final String startTime;

  /// Session end in `HH:mm`.
  final String endTime;

  /// `false` when an active booking already occupies this slot.
  final bool isAvailable;

  const AvailableSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  int get startMinutes => TimeOfDayX.tryToMinutes(startTime) ?? 0;

  int get endMinutes => TimeOfDayX.tryToMinutes(endTime) ?? 0;

  /// Stable identity of the slot inside a day.
  String get key => startTime;

  String get label =>
      '${TimeOfDayX.toDisplay(startTime)} - ${TimeOfDayX.toDisplay(endTime)}';

  AvailableSlot copyWith({String? startTime, String? endTime, bool? isAvailable}) {
    return AvailableSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [startTime, endTime, isAvailable];
}

/// Groups slots into the time buckets shown when a client picks a time.
enum SlotPeriod {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening');

  final String label;

  const SlotPeriod(this.label);

  static SlotPeriod fromStartMinutes(int minutes) {
    if (minutes < 12 * 60) return SlotPeriod.morning;
    if (minutes < 17 * 60) return SlotPeriod.afternoon;
    return SlotPeriod.evening;
  }
}

/// Sorts slots chronologically.
List<AvailableSlot> sortSlots(List<AvailableSlot> slots) {
  final sorted = List<AvailableSlot>.from(slots);
  sorted.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  return sorted;
}

/// Groups slots by [SlotPeriod], preserving chronological order.
Map<SlotPeriod, List<AvailableSlot>> groupSlotsByPeriod(
  List<AvailableSlot> slots,
) {
  final grouped = <SlotPeriod, List<AvailableSlot>>{};
  for (final slot in sortSlots(slots)) {
    final period = SlotPeriod.fromStartMinutes(slot.startMinutes);
    grouped.putIfAbsent(period, () => <AvailableSlot>[]).add(slot);
  }
  return grouped;
}
