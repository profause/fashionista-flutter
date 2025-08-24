import 'package:flutter/material.dart';

class CustomFilterButton extends StatelessWidget {
  final String title;
  final ValueNotifier<bool>? isSelectedNotifier;
  final Function(String) onSelect;

  const CustomFilterButton({
    super.key,
    required this.title,
    this.isSelectedNotifier, 
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: isSelectedNotifier!,
      builder: (_, isSelected, __) {
        return Container(
          margin: const EdgeInsets.only(right: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onSelect(title);
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall!.copyWith(
                        color: isSelected ? Colors.black : Colors.grey[700],
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
