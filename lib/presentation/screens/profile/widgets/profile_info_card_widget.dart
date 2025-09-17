import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';

class ProfileInfoCardWidget extends StatelessWidget {
  //final List<Map<String, String>> items;

  final List<ProfileInfoItem> items;

  const ProfileInfoCardWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 0),
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
                indent: 48,
              );
            }

            final itemIndex = index ~/ 2;
            final title = items[itemIndex].title;
            final value = items[itemIndex].value;
            final IconData? icon = items[itemIndex].icon;
            final Widget? suffix = items[itemIndex].suffix;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      CustomIconRounded(icon: icon),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (title.isNotEmpty) ...[
                            Text(title, style: textTheme.titleSmall),
                            const SizedBox(height: 4),
                          ],
                          if (value.isNotEmpty) ...[
                            Text(
                              value,
                              style: textTheme.labelLarge!.copyWith(
                                color: colorScheme.primary,
                              ),
                              maxLines: 2, // restrict to one line
                              overflow: TextOverflow
                                  .ellipsis, // show "..." for overflow
                              softWrap: true, // optional, keeps it single-line
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (suffix != null) ...[const Spacer(), suffix],
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class ProfileInfoItem {
  final String title;
  final String value;
  final IconData? icon;
  final Widget? suffix;

  const ProfileInfoItem({
    this.icon,
    this.suffix,
    required this.title,
    required this.value,
  });
}
