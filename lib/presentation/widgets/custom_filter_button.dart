import 'package:flutter/material.dart';

class CustomFilterButton extends StatefulWidget {
  final String? initialValue;
  final Function(String) onSelect;
  final List<String> items;

  const CustomFilterButton({
    super.key,
    required this.onSelect,
    required this.items,
    this.initialValue,
  });

  @override
  State<CustomFilterButton> createState() => _CustomFilterButtonState();
}

class _CustomFilterButtonState extends State<CustomFilterButton> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue ?? '';
    //selectValue(selectedValue);
  }

  void selectValue(String initialValue) {
    setState(() {
      selectedValue = initialValue;
    });
    widget.onSelect(initialValue);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Wrap(
        spacing: 8,
        children: widget.items.map((value) {
          final bool isSelected = selectedValue == value;
          return ChoiceChip(
            label: Text(
              value,
              style: textTheme.labelMedium!.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => selectValue(value),
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: textTheme.labelMedium!.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            //padding: EdgeInsets.zero, // remove extra padding
          );
        }).toList(),
      ),
    );
  }
}
