import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/designer_time_zone.dart';
import 'package:fashionista/data/models/availability/bloc/availability_bloc.dart';
import 'package:fashionista/data/models/availability/bloc/availability_event.dart';
import 'package:fashionista/data/models/availability/bloc/availability_state.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/presentation/screens/availability/date_exception_screen.dart';
import 'package:fashionista/presentation/screens/availability/edit_day_availability_screen.dart';
import 'package:fashionista/presentation/screens/availability/widgets/availability_conflict_dialog.dart';
import 'package:fashionista/presentation/screens/availability/widgets/day_availability_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Weekly availability configuration for a designer.
class ManageAvailabilityScreen extends StatefulWidget {
  /// Defaults to the signed-in designer.
  final String? designerId;

  const ManageAvailabilityScreen({super.key, this.designerId});

  @override
  State<ManageAvailabilityScreen> createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  late final String _designerId;
  String _deviceTimezone = '';
  bool _autoSavedTimezone = false;

  @override
  void initState() {
    super.initState();
    _designerId =
        widget.designerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadDeviceTimezone();
    context.read<AvailabilityBloc>().add(LoadAvailability(_designerId));
  }

  Future<void> _loadDeviceTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      if (!mounted) return;
      setState(() => _deviceTimezone = info.identifier);
    } catch (_) {
      // Timezone detection is best effort.
    }
  }

  void _openDay(DesignerAvailability day) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AvailabilityBloc>(),
              child: EditDayAvailabilityScreen(
                designerId: _designerId,
                day: day,
                allDays: _currentWeekly(),
                timezone: _currentTimezone(),
              ),
            ),
          ),
        )
        .then((saved) {
          if (saved == true && mounted) {
            context.read<AvailabilityBloc>().add(
              LoadAvailability(_designerId),
            );
          }
        });
  }

  void _openExceptions() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AvailabilityBloc>(),
              child: DateExceptionScreen(
                designerId: _designerId,
                allDays: _currentWeekly(),
                timezone: _currentTimezone(),
              ),
            ),
          ),
        )
        .then((saved) {
          if (saved == true && mounted) {
            context.read<AvailabilityBloc>().add(
              LoadAvailability(_designerId),
            );
          }
        });
  }

  List<DesignerAvailability> _currentWeekly() {
    final state = context.read<AvailabilityBloc>().state;
    if (state is AvailabilityLoaded) return state.weekly;
    if (state is AvailabilitySaved) return state.weekly;
    if (state is AvailabilityError) return state.weekly;
    return DesignerAvailability.emptyWeek();
  }

  String _currentTimezone() {
    final state = context.read<AvailabilityBloc>().state;
    if (state is AvailabilityLoaded) return state.timezone;
    if (state is AvailabilitySaved) return state.timezone;
    if (state is AvailabilityError) return state.timezone;
    return '';
  }

  Future<void> _changeTimezone(String current) async {
    final controller = TextEditingController(
      text: current.isEmpty ? _deviceTimezone : current,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.cardSurface,
          title: const Text('Designer timezone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Availability times are interpreted in this timezone.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'IANA timezone',
                  hintText: 'Africa/Accra',
                ),
              ),
              const SizedBox(height: 8),
              if (_deviceTimezone.isNotEmpty)
                TextButton(
                  onPressed: () {
                    controller.text = _deviceTimezone;
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text('Use device timezone ($_deviceTimezone)'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                controller.text.trim(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: dialogContext.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty || !mounted) return;

    // Validate before persisting so a typo cannot silently fall back to UTC.
    if (!DesignerTimeZone.isValidZone(result)) {
      AppToast.error(context, 'Unknown timezone "$result".');
      return;
    }

    context.read<AvailabilityBloc>().add(
      SaveTimezone(designerId: _designerId, timezone: result),
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
        title: Text(
          'Manage availability',
          style: textTheme.titleMedium,
        ),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: context.hairline)),
      ),
      body: BlocConsumer<AvailabilityBloc, AvailabilityState>(
        listenWhen: (previous, current) =>
            current is AvailabilityLoaded ||
            current is AvailabilitySaved ||
            current is AvailabilityError ||
            current is AvailabilityConflicts,
        listener: (context, state) async {
          if (state is AvailabilityLoaded &&
              state.timezone.isEmpty &&
              _deviceTimezone.isNotEmpty &&
              !_autoSavedTimezone) {
            // Requirement: the designer profile should always carry a timezone.
            _autoSavedTimezone = true;
            context.read<AvailabilityBloc>().add(
              SaveTimezone(
                designerId: _designerId,
                timezone: _deviceTimezone,
              ),
            );
            return;
          }
          if (ModalRoute.of(context)?.isCurrent != true) return;
          if (state is AvailabilitySaved) {
            AppToast.success(context, state.message);
          } else if (state is AvailabilityError) {
            AppToast.error(context, state.message);
          } else if (state is AvailabilityConflicts) {
            final bloc = context.read<AvailabilityBloc>();
            final proceed = await showAvailabilityConflictDialog(
              context,
              state.conflicts,
            );
            if (!proceed || !mounted) return;

            if (state.pendingDay != null) {
              bloc.add(
                SaveDay(
                  designerId: _designerId,
                  availability: state.pendingDay!,
                  confirmedConflicts: true,
                ),
              );
            } else if (state.pendingException != null) {
              bloc.add(
                SaveException(
                  designerId: _designerId,
                  exception: state.pendingException!,
                  confirmedConflicts: true,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is AvailabilityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            color: context.accent,
            onRefresh: () async {
              context.read<AvailabilityBloc>().add(
                LoadAvailability(_designerId),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _TimezoneCard(
                  timezone: _timezoneOf(state),
                  onChange: () => _changeTimezone(_timezoneOf(state)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Working days',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define sessions per day. Appointment slots are generated '
                  'automatically and never stored.',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: context.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 10),
                ..._weeklyOf(state).map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DayAvailabilityCard(
                      day: day,
                      onConfigure: () => _openDay(day),
                      onToggle: (value) {
                        context.read<AvailabilityBloc>().add(
                          SaveDay(
                            designerId: _designerId,
                            availability: day.copyWith(isAvailable: value),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _openExceptions,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: const Text('Date exceptions'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: context.accent,
                    side: BorderSide(color: context.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DesignerAvailability> _weeklyOf(AvailabilityState state) {
    if (state is AvailabilityLoaded) return state.weekly;
    if (state is AvailabilitySaving) return state.weekly;
    if (state is AvailabilitySaved) return state.weekly;
    if (state is AvailabilityError) return state.weekly;
    if (state is AvailabilityConflicts) return state.weekly;
    return DesignerAvailability.emptyWeek();
  }

  String _timezoneOf(AvailabilityState state) {
    if (state is AvailabilityLoaded) return state.timezone;
    if (state is AvailabilitySaving) return state.timezone;
    if (state is AvailabilitySaved) return state.timezone;
    if (state is AvailabilityError) return state.timezone;
    if (state is AvailabilityConflicts) return state.timezone;
    return '';
  }
}

class _TimezoneCard extends StatelessWidget {
  final String timezone;
  final VoidCallback onChange;

  const _TimezoneCard({required this.timezone, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasTimezone = timezone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasTimezone ? context.iconSubstrate : context.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasTimezone ? Colors.transparent : context.accent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.public,
            size: 20,
            color: hasTimezone ? context.secondaryLabel : context.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timezone',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.4,
                    color: context.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasTimezone ? timezone : 'Not set — tap to configure',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(
              hasTimezone ? 'Change' : 'Set',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 13,
                color: context.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
