import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class RadioOptionRow extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final EdgeInsetsGeometry padding;
  final ValueChanged<String> onChanged;

  const RadioOptionRow({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(vertical: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = groupValue == value;
    return Padding(
      padding: padding,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: context.onCanvasText,
              ),
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: isSelected
                      ? context.accent
                      : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3938)
                            : const Color(0xFFCBD5E1)),
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
