import 'package:flutter/material.dart';

class GenderChipFormField extends StatefulWidget {
  final String? initialGender;
  final ValueChanged<String> onChanged;

  const GenderChipFormField({
    super.key,
    this.initialGender,
    required this.onChanged,
  });

  @override
  State<GenderChipFormField> createState() => _GenderChipFormFieldState();
}

class _GenderChipFormFieldState extends State<GenderChipFormField> {
  late String selectedGender;

  @override
  void initState() {
    super.initState();
    selectedGender = widget.initialGender ?? 'Male';
  }

  void selectGender(String gender) {
    setState(() {
      selectedGender = gender;
    });
    widget.onChanged(gender);
  }

  @override
  Widget build(BuildContext context) {
    final genders = ['Male', 'Female'];
    final textTheme = Theme.of(context).textTheme;
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 4,
            ),
          ),
          child: Wrap(
            spacing: 8,
            children: genders.map((gender) {
              final bool isSelected = selectedGender == gender;
              return ChoiceChip(
                label: Text(gender),
                selected: isSelected,
                onSelected: (_) => selectGender(gender),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
