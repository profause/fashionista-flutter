import 'package:flutter/material.dart';

class ClosetItemCategoriesWidget extends StatelessWidget {
  const ClosetItemCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final categories = [
       {"label": "add", "icon": Icons.add},
      {"label": "Dresses", "icon": Icons.checkroom},
      {"label": "Tops", "icon": Icons.emoji_people},
      {"label": "T-Shirts", "icon": Icons.local_offer},
      {"label": "Sweaters", "icon": Icons.waves},
      {"label": "Jackets", "icon": Icons.dry_cleaning},
      {"label": "Skirts", "icon": Icons.crop_3_2},
      {"label": "Pants", "icon": Icons.work},
      {"label": "Shorts", "icon": Icons.directions_run},
      {"label": "Activewear", "icon": Icons.fitness_center},
      {"label": "Lingerie", "icon": Icons.nightlight_round},
      {"label": "Heels", "icon": Icons.stairs},
      {"label": "Flats", "icon": Icons.remove},
      {"label": "Sneakers", "icon": Icons.directions_walk},
      {"label": "Boots", "icon": Icons.hiking},
      {"label": "Sandals", "icon": Icons.beach_access},
      {"label": "Handbags", "icon": Icons.shopping_bag},
      {"label": "Backpacks", "icon": Icons.backpack},
      {"label": "Clutches", "icon": Icons.wallet},
      {"label": "Jewelry", "icon": Icons.diamond},
      {"label": "Hats", "icon": Icons.umbrella},
      {"label": "Scarves", "icon": Icons.texture},
      {"label": "Sunglasses", "icon": Icons.remove_red_eye},
      {"label": "Watches", "icon": Icons.watch},
      {"label": "Swimwear", "icon": Icons.pool},
      {"label": "Formal", "icon": Icons.event_seat},
      {"label": "Traditional", "icon": Icons.flag},
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          return ActionChip(
            avatar: Icon(
              item["icon"] as IconData,
              size: 18,
              color: colorScheme.primary,
            ),
            label: Text(item["label"] as String),
            onPressed: () {
              // TODO: Handle category filter
              debugPrint("Selected: ${item['label']}");
            },
          );
        },
      ),
    );
  }
}
