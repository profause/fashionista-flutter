import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/scheduling/date_key.dart';
import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:fashionista/data/models/availability/bloc/availability_bloc.dart';
import 'package:fashionista/data/models/availability/bloc/availability_event.dart';
import 'package:fashionista/data/models/availability/bloc/availability_state.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/domain/usecases/availability/fetch_availability_exceptions_usecase.dart';
import 'package:fashionista/presentation/screens/availability/widgets/availability_conflict_dialog.dart';
import 'package:fashionista/presentation/screens/availability/widgets/session_editor_tile.dart';
import 'package:fashionista/presentation/screens/availability/widgets/slot_preview_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Date-specific overrides of the weekly schedule.
class DateExceptionScreen extends StatefulWidget {
  final String designerId;
  final List<DesignerAvailability> allDays;
  final String timezone;

  const DateExceptionScreen({
    super.key,
    required this.designerId,
    required this.allDays,
    this.timezone = '',
  });

  @override
  State<DateExceptionScreen> createState() => _DateExceptionScreenState();
}

class _DateExceptionScreenState extends State<DateExceptionScreen> {
  static const List<int> _durationOptions = [15, 20, 30, 45, 60, 75, 90, 120];

  final TextEditingController _reasonController = TextEditingController();

  DateTime? _selectedDate;
  AvailabilityExceptionType _type = AvailabilityExceptionType.unavailable;
  int _duration = DesignerAvailability.defaultDurationMinutes;
  List<AvailabilitySession> _sessions = const [];
  List<AvailabilityException> _existing = const [];
  List<String> _problems = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExceptions();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadExceptions() async {
    final today = DateTime.now();
    final result = await sl<FetchAvailabilityExceptionsUsecase>()(
      FetchAvailabilityExceptionsParams(
        designerId: widget.designerId,
        dateFrom: DateKey.fromDate(today),
        dateTo: DateKey.fromDate(today.add(const Duration(days: 180))),
      ),
    );

    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _loading = false);
        AppToast.error(context, failure);
      },
      (exceptions) {
        setState(() {
          _existing = exceptions;
          _loading = false;
        });
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );

    if (picked == null) return;

    final key = DateKey.fromDate(picked);
    final existing = _existing.where((e) => e.date == key).firstOrNull;

    setState(() {
      _selectedDate = picked;
      _problems = const [];
      if (existing != null) {
        _type = existing.type;
        _reasonController.text = existing.reason ?? '';
        if (existing.isCustom) {
          _sessions = List<AvailabilitySession>.from(existing.sessions);
          _duration = existing.appointmentDurationMinutes ??
              _weekdayDuration(picked.weekday);
        }
      } else {
        _type = AvailabilityExceptionType.unavailable;
        _reasonController.clear();
        _sessions = const [];
        _duration = _weekdayDuration(picked.weekday);
      }
    });
  }

  int _weekdayDuration(int weekday) {
    for (final day in widget.allDays) {
      if (day.dayOfWeek == weekday) return day.appointmentDurationMinutes;
    }
    return DesignerAvailability.defaultDurationMinutes;
  }

  void _save() {
    final date = _selectedDate;
    if (date == null) {
      AppToast.error(context, 'Pick a date first.');
      return;
    }

    if (_type == AvailabilityExceptionType.custom) {
      final problems = SlotSchedulingService.validateSchedule(
        sessions: _sessions,
        durationMinutes: _duration,
      );
      if (problems.isNotEmpty) {
        setState(() => _problems = problems);
        return;
      }
    }

    final exception = AvailabilityException(
      date: DateKey.fromDate(date),
      type: _type,
      sessions: _type == AvailabilityExceptionType.custom
          ? SlotSchedulingService.sortSessions(_sessions)
          : const [],
      appointmentDurationMinutes:
          _type == AvailabilityExceptionType.custom ? _duration : null,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    );

    context.read<AvailabilityBloc>().add(
      SaveException(designerId: widget.designerId, exception: exception),
    );
  }

  void _delete(AvailabilityException exception) {
    context.read<AvailabilityBloc>().add(
      DeleteException(designerId: widget.designerId, date: exception.date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final List<AvailableSlot> preview =
        _type == AvailabilityExceptionType.custom
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
          _loadExceptions();
        } else if (state is AvailabilityError) {
          AppToast.error(context, state.message);
        } else if (state is AvailabilityConflicts) {
          final bloc = context.read<AvailabilityBloc>();
          final proceed = await showAvailabilityConflictDialog(
            context,
            state.conflicts,
          );
          if (!proceed || !mounted) return;
          if (state.pendingException != null) {
            bloc.add(
              SaveException(
                designerId: widget.designerId,
                exception: state.pendingException!,
                confirmedConflicts: true,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.canvasBackground,
        appBar: AppBar(
          foregroundColor: context.onCanvasText,
          backgroundColor: context.canvasBackground,
          title: Text('Date exceptions', style: textTheme.titleMedium),
          elevation: 0,
          shape: Border(bottom: BorderSide(color: context.hairline)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Override your weekly schedule for a specific date, for example '
              'a holiday or a changed working day.',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: context.secondaryLabel,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.hairline),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: context.secondaryLabel,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select a date'
                            : DateKey.fromDate(_selectedDate!),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: context.secondaryLabel,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 14),
              SegmentedButton<AvailabilityExceptionType>(
                segments: const [
                  ButtonSegment(
                    value: AvailabilityExceptionType.unavailable,
                    label: Text('Unavailable'),
                    icon: Icon(Icons.block, size: 16),
                  ),
                  ButtonSegment(
                    value: AvailabilityExceptionType.custom,
                    label: Text('Custom hours'),
                    icon: Icon(Icons.schedule, size: 16),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    _problems = const [];
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: context.accent.withValues(
                    alpha: 0.15,
                  ),
                  selectedForegroundColor: context.accent,
                  side: BorderSide(color: context.hairline),
                ),
              ),
              if (_type == AvailabilityExceptionType.custom) ...[
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
                      onSelected: (_) {
                        setState(() {
                          _duration = minutes;
                          _problems = const [];
                        });
                      },
                      selectedColor: context.accent.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? context.accent
                            : context.onCanvasText,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: selected ? context.accent : context.hairline,
                      ),
                      backgroundColor: context.cardSurface,
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
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
                      onPressed: () {
                        setState(() {
                          _sessions = [
                            ..._sessions,
                            const AvailabilitySession(
                              startTime: '09:00',
                              endTime: '12:00',
                            ),
                          ];
                          _problems = const [];
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add session'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.accent,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
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
                  const SizedBox(height: 6),
                  ..._problems.map(
                    (problem) => Text(
                      '• $problem',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Generated slots',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SlotPreviewGrid(slots: preview),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save exception'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Upcoming exceptions',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_existing.isEmpty)
              Text(
                'No date exceptions configured.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: context.secondaryLabel,
                ),
              )
            else
              ..._existing.map(
                (exception) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        exception.isCustom
                            ? Icons.schedule
                            : Icons.event_busy_outlined,
                        size: 18,
                        color: context.secondaryLabel,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exception.date,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              exception.isCustom
                                  ? '${exception.sessions.length} session(s) · '
                                        '${exception.appointmentDurationMinutes ?? _weekdayDuration(DateTime.parse(exception.date).weekday)} min'
                                  : 'Unavailable${exception.reason == null ? '' : ' · ${exception.reason}'}',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: context.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _delete(exception),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Remove exception',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
