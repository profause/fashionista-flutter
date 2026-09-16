import 'package:fashionista/core/theme/app.theme.dart';
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
    return Row(
      children: widget.items.map((value) {
        final bool isSelected = selectedValue == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => selectValue(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? context.accent : context.cardSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? context.accent : context.hairline,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.accent.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    value,
                    style: textTheme.labelMedium!.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : context.onCanvasText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}