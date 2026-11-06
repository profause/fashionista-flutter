import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/booking_sort.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_bloc.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_state.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_client_tile.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_details_sheet.dart';
import 'package:fashionista/presentation/screens/bookings/widgets/booking_status_chip.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Designer-side booking list with status actions.
class DesignerBookingsScreen extends StatefulWidget {
  final String? designerId;

  const DesignerBookingsScreen({super.key, this.designerId});

  @override
  State<DesignerBookingsScreen> createState() => _DesignerBookingsScreenState();
}

class _DesignerBookingsScreenState extends State<DesignerBookingsScreen> {
  late final String _designerId;

  BookingSortField _sortField = BookingSortField.startAt;
  bool _ascending = true;

  bool get _isDefaultSort =>
      _sortField == BookingSortField.startAt && _ascending;

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<_SortSelection>(
      context: context,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _SortBookingsSheet(field: _sortField, ascending: _ascending),
    );

    if (result == null || !mounted) return;

    setState(() {
      _sortField = result.field;
      _ascending = result.ascending;
    });
  }

  @override
  void initState() {
    super.initState();
    _designerId =
        widget.designerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    context.read<BookingBloc>().add(LoadDesignerBookings(_designerId));
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
        actorUserId: _designerId,
        actorIsDesigner: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: context.canvasBackground,
        foregroundColor: context.onCanvasText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Appointments'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openSortSheet,
            tooltip: 'Sort appointments',
            icon: Icon(
              Icons.tune,
              color: _isDefaultSort ? context.secondaryLabel : context.accent,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listenWhen: (previous, current) =>
            current is BookingActionSuccess || current is BookingError,
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          if (state is BookingActionSuccess) {
            AppToast.success(context, state.message);
            context.read<BookingBloc>().add(
              LoadDesignerBookings(_designerId, refreshOnly: true),
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
              title: 'Could not load appointments',
              subtitle: state.message,
              icon: Icons.error_outline,
            );
          }

          if (state is! BookingsLoaded ||
              state.ownerId != _designerId ||
              !state.isDesignerView) {
            return const Center(child: CircularProgressIndicator());
          }

          final upcoming = BookingSort.sorted(
            state.bookings.where((booking) => booking.status.isUpcoming),
            field: _sortField,
            ascending: _ascending,
          );
          final past = BookingSort.sorted(
            state.bookings.where((booking) => !booking.status.isUpcoming),
            field: _sortField,
            ascending: _ascending,
          );

          if (state.bookings.isEmpty) {
            return const PageEmptyWidget(
              title: 'No appointments yet',
              subtitle: 'Once clients book a slot, their requests appear here.',
              icon: Icons.event_available_outlined,
            );
          }

          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              context.read<BookingBloc>().add(
                LoadDesignerBookings(_designerId, refreshOnly: true),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (state.fromCache)
                  _CachedNotice(
                    hasError: state.refreshError != null,
                    onRetry: () => context.read<BookingBloc>().add(
                      LoadDesignerBookings(_designerId, refreshOnly: true),
                    ),
                  ),
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
                  _SectionLabel(label: 'History (${past.length})'),
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

/// Shown while the list is the offline snapshot: appointments read from the
/// device while Firestore has not answered yet.
class _CachedNotice extends StatelessWidget {
  final bool hasError;
  final VoidCallback onRetry;

  const _CachedNotice({required this.hasError, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.cloud_off_outlined : Icons.history,
            size: 18,
            color: context.secondaryLabel,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasError
                  ? 'Showing saved appointments — could not refresh.'
                  : 'Showing saved appointments…',
              style: TextStyle(fontSize: 12, color: context.secondaryLabel),
            ),
          ),
          if (hasError)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: context.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
        ],
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
                      const SizedBox(height: 6),
                      BookingClientTile(
                        client: booking.client,
                        fallbackId: booking.userId,
                        avatarSize: 30,
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

/// Result of the sort sheet.
class _SortSelection {
  final BookingSortField field;
  final bool ascending;

  const _SortSelection({required this.field, required this.ascending});
}

/// Sort sheet: choose the field (`start_at` or `created_at`) and the direction.
class _SortBookingsSheet extends StatefulWidget {
  final BookingSortField field;
  final bool ascending;

  const _SortBookingsSheet({required this.field, required this.ascending});

  @override
  State<_SortBookingsSheet> createState() => _SortBookingsSheetState();
}

class _SortBookingsSheetState extends State<_SortBookingsSheet> {
  late BookingSortField _field = widget.field;
  late bool _ascending = widget.ascending;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            const SizedBox(height: 16),
            Text(
              'Sort appointments',
              style: textTheme.titleSmall?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _SheetLabel(label: 'Sort by'),
            const SizedBox(height: 8),
            _OptionGroup<BookingSortField>(
              value: _field,
              options: const {
                BookingSortField.startAt: 'Appointment date',
                BookingSortField.createdAt: 'Request date',
              },
              onChanged: (value) => setState(() => _field = value),
            ),
            const SizedBox(height: 18),
            _SheetLabel(label: 'Order'),
            const SizedBox(height: 8),
            _OptionGroup<bool>(
              value: _ascending,
              options: const {true: 'Ascending', false: 'Descending'},
              onChanged: (value) => setState(() => _ascending = value),
            ),
            const SizedBox(height: 6),
            Text(
              _ascending
                  ? 'Earliest first for the selected date field.'
                  : 'Latest first for the selected date field.',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: context.secondaryLabel,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    const _SortSelection(
                      field: BookingSortField.startAt,
                      ascending: true,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: context.secondaryLabel,
                  ),
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_SortSelection(field: _field, ascending: _ascending)),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String label;

  const _SheetLabel({required this.label});

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

/// Segmented choice rendered as tappable pills (avoids nesting list tiles in a
/// decorated surface).
class _OptionGroup<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _OptionGroup({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in options.entries) ...[
          Expanded(
            child: _OptionPill(
              label: entry.value,
              selected: entry.key == value,
              onTap: () => onChanged(entry.key),
            ),
          ),
          if (entry.key != options.keys.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _OptionPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.accent.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.accent : context.hairline,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? context.accent : context.onCanvasText,
            ),
          ),
        ),
      ),
    );
  }
}
