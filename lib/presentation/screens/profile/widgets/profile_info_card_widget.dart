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
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(items.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Divider between items
              return Divider(height: 16, thickness: 1, color: Colors.grey[300]);
            }

            final itemIndex = index ~/ 2;
            final title = items[itemIndex].title;
            final value = items[itemIndex].value;
            final IconData? icon = items[itemIndex].icon;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconRounded(icon: icon!),
                    const SizedBox(width: 16),
                    //Expanded(
                    //child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: textTheme.labelLarge!.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    //),
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

  ProfileInfoItem(this.icon, {required this.title, required this.value});
}
