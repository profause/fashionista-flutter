import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_bloc.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_state.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_details_sheet.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_status_chip.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Client-side list of the signed-in user's bookings.
class MyBookingsScreen extends StatefulWidget {
  final String? userId;

  const MyBookingsScreen({super.key, this.userId});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    context.read<BookingBloc>().add(LoadMyBookings(_userId));
  }

  void _open(Booking booking) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookingDetailsSheet(
        booking: booking,
        actorUserId: _userId,
        actorIsDesigner: false,
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
        title: Text('My bookings', style: textTheme.titleMedium),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: context.hairline)),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listenWhen: (previous, current) =>
            current is BookingActionSuccess || current is BookingError,
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          if (state is BookingActionSuccess) {
            AppToast.success(context, state.message);
            context.read<BookingBloc>().add(
              LoadMyBookings(_userId, refreshOnly: true),
            );
          } else if (state is BookingError) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is BookingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingError) {
            return PageEmptyWidget(
              title: 'Could not load your bookings',
              subtitle: state.message,
              icon: Icons.error_outline,
            );
          }

          if (state is! BookingsLoaded ||
              state.ownerId != _userId ||
              state.isDesignerView) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.bookings.isEmpty) {
            return const PageEmptyWidget(
              title: 'No bookings yet',
              subtitle:
                  'Pick a designer and book an appointment to see it here.',
              icon: Icons.event_note_outlined,
            );
          }

          final upcoming = state.bookings
              .where((booking) => booking.status.isUpcoming)
              .toList()
            ..sort(
              (a, b) => (a.startAt ?? DateTime(0)).compareTo(
                b.startAt ?? DateTime(0),
              ),
            );
          final past = state.bookings
              .where((booking) => !booking.status.isUpcoming)
              .toList();

          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              context.read<BookingBloc>().add(
                LoadMyBookings(_userId, refreshOnly: true),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionLabel(label: 'Upcoming (${upcoming.length})'),
                  const SizedBox(height: 8),
                  ...upcoming.map(
                    (booking) => _BookingTile(
                      booking: booking,
                      onTap: () => _open(booking),
                    ),
                  ),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionLabel(label: 'Past (${past.length})'),
                  const SizedBox(height: 8),
                  ...past.map(
                    (booking) => _BookingTile(
                      booking: booking,
                      onTap: () => _open(booking),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 11,
        letterSpacing: 0.4,
        color: context.secondaryLabel,
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = DateTime.tryParse(booking.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: context.iconSubstrate,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        date == null
                            ? '--'
                            : DateFormat('MMM').format(date).toUpperCase(),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: context.secondaryLabel,
                        ),
                      ),
                      Text(
                        date == null ? '--' : '${date.day}',
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${TimeOfDayX.toDisplay(booking.startTime)} - '
                        '${TimeOfDayX.toDisplay(booking.endTime)}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.notes?.isNotEmpty == true
                            ? booking.notes!
                            : 'Appointment request',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: context.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BookingStatusChip(status: booking.status),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: context.secondaryLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
