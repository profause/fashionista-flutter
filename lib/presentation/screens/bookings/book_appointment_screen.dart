import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/date_key.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_bloc.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/domain/usecases/designers/find_designer_by_id_usecase.dart';
import 'package:fashionista/presentation/screens/bookings/booking_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Step 1 of booking: pick a date, then an available slot.
class BookAppointmentScreen extends StatefulWidget {
  final String designerId;
  final String? designerName;

  const BookAppointmentScreen({
    super.key,
    required this.designerId,
    this.designerName,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const int _horizonDays = 30;

  late List<DateTime> _dates;
  late DateTime _selectedDate;
  Designer? _designer;
  AvailableSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(
      _horizonDays,
      (index) => DateTime(today.year, today.month, today.day)
          .add(Duration(days: index)),
    );
    _selectedDate = _dates.first;
    _loadDesigner();
    _loadSlots(_selectedDate);
  }

  Future<void> _loadDesigner() async {
    final result = await sl<FindDesignerByIdUsecase>()(widget.designerId);
    if (!mounted) return;
    result.fold((_) => null, (value) {
      if (value is Designer) setState(() => _designer = value);
    });
  }

  void _loadSlots(DateTime date) {
    setState(() => _selectedSlot = null);
    context.read<BookingBloc>().add(
      LoadAvailableSlots(
        designerId: widget.designerId,
        date: DateKey.fromDate(date),
      ),
    );
  }

  void _continue(AvailableSlot slot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          designerId: widget.designerId,
          designerName: _designer?.name ?? widget.designerName ?? 'Designer',
          date: DateKey.fromDate(_selectedDate),
          slot: slot,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        foregroundColor: context.onCanvasText,
        backgroundColor: context.canvasBackground,
        title: Text('Book appointment', style: textTheme.titleMedium),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: context.hairline)),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listenWhen: (previous, current) => current is BookingError,
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          if (state is BookingError) AppToast.error(context, state.message);
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (_designer != null)
                Text(
                  'with ${_designer!.name}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: context.secondaryLabel,
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final date = _dates[index];
                    final selected =
                        DateKey.fromDate(date) == DateKey.fromDate(_selectedDate);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = date);
                        _loadSlots(date);
                      },
                      child: Container(
                        width: 58,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? context.accent
                              : context.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? context.accent : context.hairline,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(date),
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: selected
                                    ? Colors.white70
                                    : context.secondaryLabel,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${date.day}',
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : context.onCanvasText,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date),
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: selected
                                    ? Colors.white70
                                    : context.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (state is AvailableSlotsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is BookingError)
                _EmptySlots(message: state.message)
              else if (state is AvailableSlotsLoaded &&
                  state.designerId == widget.designerId &&
                  state.date == DateKey.fromDate(_selectedDate))
                _buildSlots(context, state.slots)
              else
                const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlots(BuildContext context, List<AvailableSlot> slots) {
    if (slots.isEmpty) {
      return const _EmptySlots(
        message: 'No appointment slots are available on this date.',
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final grouped = groupSlotsByPeriod(slots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Text(
            entry.key.label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              letterSpacing: 0.4,
              color: context.secondaryLabel,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.value.map((slot) {
              final selected = _selectedSlot?.key == slot.key;
              final enabled = slot.isAvailable;

              return GestureDetector(
                onTap: enabled ? () => setState(() => _selectedSlot = slot) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.accent
                        : enabled
                        ? context.cardSurface
                        : context.iconSubstrate,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? context.accent
                          : context.hairline,
                    ),
                  ),
                  child: Text(
                    TimeOfDayX.toDisplay(slot.startTime),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : enabled
                          ? context.onCanvasText
                          : context.placeholderText,
                      decoration: enabled ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],
        FilledButton(
          onPressed: _selectedSlot == null
              ? null
              : () => _continue(_selectedSlot!),
          style: FilledButton.styleFrom(
            backgroundColor: context.accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _EmptySlots extends StatelessWidget {
  final String message;

  const _EmptySlots({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 18,
            color: context.secondaryLabel,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: context.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
