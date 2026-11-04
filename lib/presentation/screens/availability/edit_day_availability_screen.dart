import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:fashionista/data/models/availability/bloc/availability_bloc.dart';
import 'package:fashionista/data/models/availability/bloc/availability_event.dart';
import 'package:fashionista/data/models/availability/bloc/availability_state.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/presentation/screens/availability/widgets/availability_conflict_dialog.dart';
import 'package:fashionista/presentation/screens/availability/widgets/session_editor_tile.dart';
import 'package:fashionista/presentation/screens/availability/widgets/slot_preview_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Edits a single weekday: enabled flag, appointment duration and sessions.
class EditDayAvailabilityScreen extends StatefulWidget {
  final String designerId;
  final DesignerAvailability day;
  final List<DesignerAvailability> allDays;
  final String timezone;

  const EditDayAvailabilityScreen({
    super.key,
    required this.designerId,
    required this.day,
    required this.allDays,
    this.timezone = '',
  });

  @override
  State<EditDayAvailabilityScreen> createState() =>
      _EditDayAvailabilityScreenState();
}

class _EditDayAvailabilityScreenState extends State<EditDayAvailabilityScreen> {
  static const List<int> _durationOptions = [15, 20, 30, 45, 60, 75, 90, 120];

  late bool _isAvailable;
  late int _duration;
  late List<AvailabilitySession> _sessions;
  List<String> _problems = const [];

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.day.isAvailable;
    _duration = widget.day.appointmentDurationMinutes;
    _sessions = List<AvailabilitySession>.from(widget.day.sessions);
  }

  DesignerAvailability _build() {
    return widget.day.copyWith(
      isAvailable: _isAvailable,
      appointmentDurationMinutes: _duration,
      sessions: _isAvailable
          ? SlotSchedulingService.sortSessions(_sessions)
          : const [],
      updatedAt: DateTime.now().toUtc(),
    );
  }

  void _validate() {
    if (!_isAvailable) {
      setState(() => _problems = const []);
      return;
    }
    setState(() {
      _problems = SlotSchedulingService.validateSchedule(
        sessions: _sessions,
        durationMinutes: _duration,
      );
    });
  }

  void _addSession() {
    final last = _sessions.isEmpty ? null : _sessions.last;
    final nextStart = last == null
        ? '09:00'
        : _addMinutes(last.endTime, _duration);
    final nextEnd = _addMinutes(nextStart, _duration);

    setState(() {
      _sessions = [
        ..._sessions,
        AvailabilitySession(startTime: nextStart, endTime: nextEnd),
      ];
      _problems = const [];
    });
  }

  String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    final clamped = total % (24 * 60);
    return '${(clamped ~/ 60).toString().padLeft(2, '0')}:'
        '${(clamped % 60).toString().padLeft(2, '0')}';
  }

  void _save({bool confirmedConflicts = false}) {
    _validate();
    if (_problems.isNotEmpty) return;

    FocusScope.of(context).unfocus();

    context.read<AvailabilityBloc>().add(
      SaveDay(
        designerId: widget.designerId,
        availability: _build(),
        confirmedConflicts: confirmedConflicts,
      ),
    );
  }

  void _clearDay() {
    setState(() {
      _isAvailable = false;
      _sessions = [];
      _problems = const [];
    });
    context.read<AvailabilityBloc>().add(
      SaveDay(
        designerId: widget.designerId,
        availability: _build(),
      ),
    );
  }

  Future<void> _copyFromDay() async {
    final others = widget.allDays
        .where((day) => day.dayOfWeek != widget.day.dayOfWeek)
        .toList();

    if (others.isEmpty) return;

    final selected = await showModalBottomSheet<DesignerAvailability>(
      context: context,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Copy availability from',
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...others.map(
                (day) => ListTile(
                  title: Text(day.dayName),
                  subtitle: Text(
                    day.isAvailable
                        ? '${day.sessions.length} session(s) · '
                              '${day.appointmentDurationMinutes} min'
                        : 'Unavailable',
                  ),
                  enabled: day.isAvailable && day.sessions.isNotEmpty,
                  trailing: const Icon(Icons.content_copy, size: 18),
                  onTap: () => Navigator.of(sheetContext).pop(day),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _isAvailable = true;
      _duration = selected.appointmentDurationMinutes;
      _sessions = List<AvailabilitySession>.from(selected.sessions);
      _problems = const [];
    });
  }

  Future<void> _applyToDays() async {
    _validate();
    if (_problems.isNotEmpty) return;

    // Captured before the sheet await so no BuildContext is used afterwards.
    final bloc = context.read<AvailabilityBloc>();

    final others = widget.allDays
        .where((day) => day.dayOfWeek != widget.day.dayOfWeek)
        .toList();

    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      backgroundColor: context.cardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final chosen = <int>{};

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply ${widget.day.dayName} schedule to',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...others.map(
                      (day) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(day.dayName),
                        value: chosen.contains(day.dayOfWeek),
                        activeColor: sheetContext.accent,
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              chosen.add(day.dayOfWeek);
                            } else {
                              chosen.remove(day.dayOfWeek);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: chosen.isEmpty
                          ? null
                          : () => Navigator.of(
                              sheetContext,
                            ).pop(chosen.toList()),
                      style: FilledButton.styleFrom(
                        backgroundColor: sheetContext.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null || selected.isEmpty) return;

    final config = _build();

    // Save this day first (the screen pops on success), then queue the rest.
    bloc.add(
      SaveDay(designerId: widget.designerId, availability: config),
    );

    for (final dayOfWeek in selected) {
      bloc.add(
        SaveDay(
          designerId: widget.designerId,
          availability: DesignerAvailability(
            dayOfWeek: dayOfWeek,
            isAvailable: config.isAvailable,
            appointmentDurationMinutes: config.appointmentDurationMinutes,
            sessions: config.sessions,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final List<AvailableSlot> preview = _isAvailable
        ? SlotSchedulingService.generateSlots(
            sessions: _sessions,
            durationMinutes: _duration,
          )
        : const <AvailableSlot>[];

    return BlocListener<AvailabilityBloc, AvailabilityState>(
      listenWhen: (previous, current) =>
          current is AvailabilitySaved ||
          current is AvailabilityError ||
          current is AvailabilityConflicts,
      listener: (context, state) async {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state is AvailabilitySaved) {
          AppToast.success(context, state.message);
          if (mounted) Navigator.of(context).pop(true);
        } else if (state is AvailabilityError) {
          AppToast.error(context, state.message);
        } else if (state is AvailabilityConflicts) {
          final proceed = await showAvailabilityConflictDialog(
            context,
            state.conflicts,
          );
          if (!proceed || !mounted) return;
          if (state.pendingDay != null) {
            _save(confirmedConflicts: true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.canvasBackground,
        appBar: AppBar(
          foregroundColor: context.onCanvasText,
          backgroundColor: context.canvasBackground,
          title: Text(widget.day.dayName, style: textTheme.titleMedium),
          elevation: 0,
          shape: Border(bottom: BorderSide(color: context.hairline)),
          actions: [
            PopupMenuButton<String>(
              color: context.cardSurface,
              onSelected: (value) {
                switch (value) {
                  case 'copy':
                    _copyFromDay();
                  case 'apply':
                    _applyToDays();
                  case 'clear':
                    _clearDay();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'copy', child: Text('Copy from day')),
                PopupMenuItem(value: 'apply', child: Text('Apply to days')),
                PopupMenuItem(value: 'clear', child: Text('Clear day')),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: context.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.hairline),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isAvailable,
                  activeThumbColor: context.accent,
                  title: Text(
                    'Available on ${widget.day.dayName}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _isAvailable
                        ? 'Clients can book generated slots on this day.'
                        : 'No appointments can be booked on this day.',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: context.secondaryLabel,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                      _problems = const [];
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Appointment duration',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durationOptions.map((minutes) {
                final selected = minutes == _duration;
                return ChoiceChip(
                  label: Text('$minutes min'),
                  selected: selected,
                  onSelected: _isAvailable
                      ? (_) {
                          setState(() {
                            _duration = minutes;
                            _problems = const [];
                          });
                        }
                      : null,
                  selectedColor: context.accent.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: selected ? context.accent : context.onCanvasText,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: selected ? context.accent : context.hairline,
                  ),
                  backgroundColor: context.cardSurface,
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sessions',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isAvailable ? _addSession : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add session'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.accent,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!_isAvailable)
              Text(
                'Enable this day to add sessions.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: context.secondaryLabel,
                ),
              )
            else if (_sessions.isEmpty)
              Text(
                'No sessions yet.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: context.secondaryLabel,
                ),
              )
            else
              ..._sessions.map(
                (session) => SessionEditorTile(
                  session: session,
                  onChanged: (updated) {
                    setState(() {
                      final index = _sessions.indexOf(session);
                      if (index != -1) _sessions[index] = updated;
                      _problems = const [];
                    });
                  },
                  onDelete: () {
                    setState(() {
                      _sessions.remove(session);
                      _problems = const [];
                    });
                  },
                ),
              ),
            if (_problems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _problems
                      .map(
                        (problem) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $problem',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Generated slots',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SlotPreviewGrid(
              slots: _isAvailable ? preview : const [],
              emptyMessage: _isAvailable
                  ? 'No slots — check durations and sessions.'
                  : 'This day is marked unavailable.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _save(),
              style: FilledButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
