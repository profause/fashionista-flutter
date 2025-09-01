import 'package:fashionista/core/assets/app_images.dart';
import 'package:flutter/material.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text("Fashionista", style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundImage: AssetImage(
                AppImages.avatar,
              ), // replace with user profile
            ),
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔍 Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: "Search outfits, designers, styles...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colorScheme.onPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 🏷️ Categories
          Text("Categories", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip("Dresses", colorScheme),
                _chip("Casual", colorScheme),
                _chip("Traditional", colorScheme),
                _chip("Office", colorScheme),
                _chip("Party", colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 🌟 Featured Designers
          Text("Top Designers", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          NetworkImage("https://placehold.co/100x100.jpg"),
                    ),
                    const SizedBox(height: 6),
                    Text("Designer ${index + 1}", style: textTheme.bodySmall),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 👗 Trending Outfits
          Text("Trending Outfits", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "https://placehold.co/300x200.jpg",
                    width: 160,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ❤️ Favorites Preview
          Text("Your Favorites", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://placehold.co/100.jpg",
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 🛒 Closet (User uploaded outfits)
          Text("My Closet", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://placehold.co/100.jpg",
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Category Chip
  Widget _chip(String label, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
