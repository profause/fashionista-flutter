import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerFormField extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<DateTime?> onChanged;

  const DatePickerFormField({
    super.key,
    required this.label,
    this.initialDate,
    this.validator,
    required this.onChanged,
    required this.controller,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<DatePickerFormField> createState() => _DatePickerFormFieldState();
}

class _DatePickerFormFieldState extends State<DatePickerFormField> {
  late TextEditingController _controller;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    _controller = TextEditingController(
      text: selectedDate != null
          ? DateFormat.yMMMd().format(selectedDate!)
          : '',
    );
  }

  Future<void> _pickDate() async {
    DateTime initialDate = selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _controller.text = DateFormat.yMMMd().format(picked);
      });
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        TextFormField(
          controller: _controller,
          readOnly: true,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            //labelText: widget.label,
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 0,
            ),
          ),

          validator: widget.validator,
          onTap: _pickDate,
        ),
      ],
    );
  }
}
