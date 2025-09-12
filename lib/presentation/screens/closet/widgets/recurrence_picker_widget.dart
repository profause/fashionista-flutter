import 'package:flutter/material.dart';

enum RecurrenceType { none, daily, weekly, monthly }

class RecurrencePickerWidget extends StatefulWidget {
  final RecurrenceType initialValue;
  final List<int> initialWeekDays; // 1 = Monday, 7 = Sunday
  final Function(RecurrenceType, List<int>) onChanged;

  const RecurrencePickerWidget({
    super.key,
    this.initialValue = RecurrenceType.none,
    this.initialWeekDays = const [],
    required this.onChanged,
  });

  @override
  State<RecurrencePickerWidget> createState() => _RecurrencePickerWidgetState();
}

class _RecurrencePickerWidgetState extends State<RecurrencePickerWidget> {
  late RecurrenceType _selectedType;
  late List<int> _selectedWeekDays;

  final weekDayLabels = const {
    1: "Mon",
    2: "Tue",
    3: "Wed",
    4: "Thu",
    5: "Fri",
    6: "Sat",
    7: "Sun",
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialValue;
    _selectedWeekDays = List<int>.from(widget.initialWeekDays);
  }

  void _onTypeChanged(RecurrenceType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      if (_selectedType != RecurrenceType.weekly) {
        _selectedWeekDays.clear();
      }
    });
    widget.onChanged(_selectedType, _selectedWeekDays);
  }

  void _toggleWeekDay(int day) {
    setState(() {
      if (_selectedWeekDays.contains(day)) {
        _selectedWeekDays.remove(day);
      } else {
        _selectedWeekDays.add(day);
      }
    });
    widget.onChanged(_selectedType, _selectedWeekDays);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RecurrenceType>(
          elevation: 1,
          isExpanded: false,
          value: _selectedType,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 0,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: RecurrenceType.none,
              child: Text("Does not repeat", style: textTheme.bodyMedium),
            ),
            DropdownMenuItem(
              value: RecurrenceType.daily,
              child: Text("Daily", style: textTheme.bodyMedium),
            ),
            DropdownMenuItem(
              value: RecurrenceType.weekly,
              child: Text("Weekly", style: textTheme.bodyMedium),
            ),
            DropdownMenuItem(
              value: RecurrenceType.monthly,
              child: Text("Monthly", style: textTheme.bodyMedium),
            ),
          ],
          onChanged: _onTypeChanged,
        ),

        const SizedBox(height: 12),

        if (_selectedType == RecurrenceType.weekly)
          Wrap(
            spacing: 8,
            children: weekDayLabels.entries.map((entry) {
              final isSelected = _selectedWeekDays.contains(entry.key);
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                selectedColor: colorScheme.primary,
                onSelected: (_) => _toggleWeekDay(entry.key),
                //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
      ],
    );
  }
}
