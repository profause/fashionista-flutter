import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

final categories = [
      //{"label": "add", "icon": Icons.add},
      {"label": "Dresses", "icon": HugeIcons.strokeRoundedDress01},
      {"label": "Tops", "icon": Icons.emoji_people_outlined},
      {"label": "Trousers", "icon": HugeIcons.strokeRoundedJoggerPants},
      {"label": "T-Shirts", "icon": HugeIcons.strokeRoundedTShirt},
      {"label": "Shirts", "icon": HugeIcons.strokeRoundedShirt01},
      {"label": "Sweaters", "icon": Icons.waves_outlined},
      {"label": "Jackets", "icon": HugeIcons.strokeRoundedLongSleeveShirt},
      {"label": "Skirts", "icon": Icons.crop_3_2_outlined},
      {"label": "Pants", "icon": HugeIcons.strokeRoundedJoggerPants},
      {"label": "Shorts", "icon": HugeIcons.strokeRoundedShortsPants},
      {"label": "Activewear", "icon": Icons.fitness_center_outlined},
      {"label": "Lingerie", "icon": Icons.nightlight_round_outlined},
      {"label": "Heels", "icon": Icons.stairs_outlined},
      {"label": "Flats", "icon": Icons.remove_outlined},
      {"label": "Sneakers", "icon": Icons.directions_walk_outlined},
      {"label": "Boots", "icon": Icons.hiking_outlined},
      {"label": "Sandals", "icon": Icons.beach_access_outlined},
      {"label": "Handbags", "icon": Icons.shopping_bag_outlined},
      {"label": "Backpacks", "icon": Icons.backpack_outlined},
      {"label": "Clutches", "icon": Icons.wallet_outlined},
      {"label": "Jewelry", "icon": Icons.diamond_outlined},
      {"label": "Hats", "icon": HugeIcons.strokeRoundedHat},
      {"label": "Scarves", "icon": Icons.texture_outlined},
      {"label": "Sunglasses", "icon": HugeIcons.strokeRoundedGlasses},
      {"label": "Watches", "icon": Icons.watch_outlined},
      {"label": "Swimwear", "icon": Icons.pool_outlined},
      {"label": "Formal", "icon": Icons.event_seat_outlined},
      {"label": "Traditional", "icon": Icons.flag_outlined},
      {"label": "Casual", "icon": Icons.holiday_village_outlined},];

class ClosetItemCategoriesWidget extends StatelessWidget {
  const ClosetItemCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
