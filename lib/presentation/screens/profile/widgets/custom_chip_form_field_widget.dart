import 'package:flutter/material.dart';

class CustomChipFormFieldWidget extends StatefulWidget {
  final String? initialValue;
  final String? label;
  final ValueChanged<String> onChanged;
  final List<String> items;

  const CustomChipFormFieldWidget({
    super.key,
    this.initialValue,
    required this.label,
    required this.onChanged,
    required this.items,
  });

  @override
  State<CustomChipFormFieldWidget> createState() => _CustomChipFormFieldState();
}

class _CustomChipFormFieldState extends State<CustomChipFormFieldWidget> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue ?? '';
    selectValue(selectedValue);
  }

  void selectValue(String initialValue) {
    setState(() {
      selectedValue = initialValue;
    });
    widget.onChanged(initialValue);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Text(
            widget.label ?? '',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
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
              horizontal: 0,
            ),
          ),
          child: Wrap(
            spacing: 8,
            children: widget.items.map((value) {
              final bool isSelected = selectedValue == value;
              return ChoiceChip(
                label: Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => selectValue(value),
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
