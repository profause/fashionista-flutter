import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_bloc.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_state.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_client_tile.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_details_sheet.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Whose upcoming appointments a [UpcomingAppointmentsSection] displays.
enum AppointmentPerspective {
  /// The signed-in user booked the appointment; show the designer.
  client,

  /// The signed-in user is the designer; show the requesting client.
  designer,
}

/// "Upcoming appointments" row for the For You tab.
///
/// Works from either side of a booking: clients see their own requests with the
/// designer's name, designers see the requests made to them with the client's
/// name and avatar. The section hides itself when nothing is upcoming.
class UpcomingAppointmentsSection extends StatefulWidget {
  final String userId;
  final AppointmentPerspective perspective;

  const UpcomingAppointmentsSection({
    super.key,
    required this.userId,
    this.perspective = AppointmentPerspective.client,
  });

  bool get isDesigner => perspective == AppointmentPerspective.designer;

  @override
  State<UpcomingAppointmentsSection> createState() =>
      _UpcomingAppointmentsSectionState();
}

class _UpcomingAppointmentsSectionState
    extends State<UpcomingAppointmentsSection> {
  /// Designer names (and their in-flight lookups) keyed by designer id, so the
  /// row never re-reads Firestore while scrolling.
  final Map<String, Future<String>> _designerNameFutures = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UpcomingAppointmentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.perspective != widget.perspective) {
      _designerNameFutures.clear();
      _load();
    }
  }

  void _load() {
    if (widget.userId.isEmpty) return;

    context.read<BookingBloc>().add(
      widget.isDesigner
          ? LoadDesignerBookings(widget.userId)
          : LoadMyBookings(widget.userId),
    );
  }

  List<Booking> _upcomingOf(BookingState state) {
    if (state is! BookingsLoaded) return const [];
    if (state.ownerId != widget.userId) return const [];
    if (state.isDesignerView != widget.isDesigner) return const [];

    final now = DateTime.now().toUtc();
    return state.bookings.where((booking) {
      if (!booking.status.isUpcoming) return false;
      final startAt = booking.startAt;
      return startAt != null && startAt.isAfter(now);
    }).toList()..sort(
      (a, b) => (a.startAt ?? DateTime(0)).compareTo(b.startAt ?? DateTime(0)),
    );
  }

  Future<String> _designerName(String designerId) {
    return _designerNameFutures.putIfAbsent(designerId, () async {
      final result = await sl<FirebaseDesignersService>().findDesignerById(
        designerId,
      );
      return result.fold(
        (_) => 'Designer',
        (designer) => designer.name.trim().isEmpty ? 'Designer' : designer.name,
      );
    });
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
        actorUserId: widget.userId,
        actorIsDesigner: widget.isDesigner,
      ),
    );
  }

  void _openAll() {
    if (widget.isDesigner) {
      context.push(
        Uri(
          path: '/designer-bookings',
          queryParameters: {'designerId': widget.userId},
        ).toString(),
      );
    } else {
      context.push('/my-bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<BookingBloc, BookingState>(
      // A booking created on another screen should appear here immediately.
      listenWhen: (previous, current) =>
          current is BookingCreated && previous is! BookingCreated,
      listener: (context, state) => _load(),
      child: BlocBuilder<BookingBloc, BookingState>(
        buildWhen: (previous, current) =>
            current is BookingsLoaded ||
            current is BookingActionSuccess ||
            current is BookingsLoading,
        builder: (context, state) {
          final upcoming = _upcomingOf(state);

          // Hidden until there is an appointment to show.
          if (upcoming.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Upcoming appointments',
                      style: textTheme.titleSmall!.copyWith(fontSize: 15),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _openAll,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View all',
                        style: textTheme.labelSmall!.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: context.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: upcoming.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final booking = upcoming[index];
                      return _AppointmentCard(
                        booking: booking,
                        designerNameFuture: widget.isDesigner
                            ? null
                            : _designerName(booking.designerId),
                        onTap: () => _open(booking),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Booking booking;

  /// Resolved designer name for the client view; `null` on the designer view,
  /// which shows the booking's client snapshot instead.
  final Future<String>? designerNameFuture;

  final VoidCallback onTap;

  const _AppointmentCard({
    required this.booking,
    required this.designerNameFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = DateTime.tryParse(booking.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 236,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date == null
                          ? '--'
                          : DateFormat('MMM').format(date).toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 0.4,
                        color: context.secondaryLabel,
                      ),
                    ),
                    Text(
                      date == null ? '--' : '${date.day}',
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _identity(context),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${TimeOfDayX.toDisplay(booking.startTime)} - '
                            '${TimeOfDayX.toDisplay(booking.endTime)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: context.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity(BuildContext context) {
    final future = designerNameFuture;

    if (future == null) {
      // Designer view: the client who booked, straight from the snapshot.
      return BookingClientTile(
        client: booking.client,
        fallbackId: booking.userId,
        avatarSize: 24,
        showMobile: true,
      );
    }

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? 'Loading…',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
