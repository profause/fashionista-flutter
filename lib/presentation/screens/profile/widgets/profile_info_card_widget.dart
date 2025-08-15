import 'package:flutter/material.dart';

class ProfileInfoCardWidget extends StatelessWidget {
  final List<Map<String, String>> items;

  const ProfileInfoCardWidget({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(items.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Divider between items
              return Divider(
                height: 16,
                thickness: 1,
                color: Colors.grey[300],
              );
            }

            final itemIndex = index ~/ 2;
            final title = items[itemIndex]['title'] ?? '';
            final value = items[itemIndex]['value'] ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyMedium,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
