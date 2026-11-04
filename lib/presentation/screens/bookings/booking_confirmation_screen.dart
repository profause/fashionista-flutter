import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_bloc.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_state.dart';
import 'package:fashionista/data/models/bookings/create_booking_request.dart';
import 'package:fashionista/presentation/screens/bookings/booking_status_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Step 2 of booking: review the appointment and submit the request.
class BookingConfirmationScreen extends StatefulWidget {
  final String designerId;
  final String designerName;
  final String date;
  final AvailableSlot slot;

  const BookingConfirmationScreen({
    super.key,
    required this.designerId,
    required this.designerName,
    required this.date,
    required this.slot,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      AppToast.error(context, 'Please sign in to book an appointment.');
      return;
    }

    final parsed = DateTime.tryParse(widget.date);
    if (parsed == null) {
      AppToast.error(context, 'This date is invalid. Pick another one.');
      return;
    }

    setState(() => _submitting = true);

    context.read<BookingBloc>().add(
      CreateBooking(
        CreateBookingRequest(
          designerId: widget.designerId,
          userId: userId,
          date: widget.date,
          dayOfWeek: parsed.weekday,
          startTime: widget.slot.startTime,
          endTime: widget.slot.endTime,
          timezone: '',
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<BookingBloc, BookingState>(
      listenWhen: (previous, current) =>
          current is BookingCreated ||
          current is BookingError ||
          current is BookingSubmitting,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state is BookingCreated) {
          setState(() => _submitting = false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BookingStatusScreen(booking: state.booking),
            ),
          );
        } else if (state is BookingError) {
          setState(() => _submitting = false);
          AppToast.error(context, state.message);
        }
      },
      builder: (context, state) {
        final busy = _submitting || state is BookingSubmitting;

        return Scaffold(
          backgroundColor: context.canvasBackground,
          appBar: AppBar(
            foregroundColor: context.onCanvasText,
            backgroundColor: context.canvasBackground,
            title: Text('Confirm booking', style: textTheme.titleMedium),
            elevation: 0,
            shape: Border(bottom: BorderSide(color: context.hairline)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row(label: 'Designer', value: widget.designerName),
                    Divider(height: 18, color: context.hairline),
                    _Row(
                      label: 'Date',
                      value: _formatDate(widget.date),
                    ),
                    Divider(height: 18, color: context.hairline),
                    _Row(
                      label: 'Time',
                      value:
                          '${TimeOfDayX.toDisplay(widget.slot.startTime)} - '
                          '${TimeOfDayX.toDisplay(widget.slot.endTime)}',
                    ),
                    Divider(height: 18, color: context.hairline),
                    _Row(
                      label: 'Duration',
                      value:
                          '${widget.slot.endMinutes - widget.slot.startMinutes} minutes',
                    ),
                    Divider(height: 18, color: context.hairline),
                    _Row(
                      label: 'Client',
                      value:
                          FirebaseAuth.instance.currentUser?.phoneNumber ?? 'You',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _notesController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Notes for the designer (optional)',
                  hintText: 'e.g. I would like to discuss my wedding outfit.',
                  filled: true,
                  fillColor: context.cardSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The slot is held for a short time while the designer reviews '
                'your request.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: context.secondaryLabel,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Request booking'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('EEEE, d MMMM yyyy').format(parsed);
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: context.secondaryLabel,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
