import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Compact pill toggle used across settings-style rows.
///
/// Renders as a 44x24 track with a sliding white thumb, tinted with the brand
/// accent when on. Use it instead of a [Switch] where the platform switch looks
/// too heavy for the surrounding card.
class RoundToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RoundToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? context.accent : context.softBorder,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 2,
                  offset: Offset(0, 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
