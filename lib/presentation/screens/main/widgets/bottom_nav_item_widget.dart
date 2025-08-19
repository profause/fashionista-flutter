//import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class BottomNavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueNotifier<int> selectedIndex;
  final ValueChanged<int> onTap;
  final double? iconSize;

  const BottomNavItem({
    super.key,
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selectedIndex,
    required this.onTap,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: selectedIndex,
      builder: (_, currentIndex, __) {
        bool isSelected = currentIndex == index;
        return InkWell(
          onTap: () {
            selectedIndex.value = index;
            onTap(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                  size: iconSize,
                ),
                const SizedBox(height: 4),
                // Text(
                //   label,
                //   style: TextStyle(
                //     color: isSelected
                //         ? colorScheme.onPrimary
                //         : colorScheme.primary,
                //     fontSize: 12,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}
