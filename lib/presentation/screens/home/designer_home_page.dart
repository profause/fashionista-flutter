import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/assets/app_images.dart';
import 'package:flutter/material.dart';

class DesignerHomePage extends StatelessWidget {
  const DesignerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔍 Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: "Search clients, designs...",
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

          // ⚡ Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(Icons.people_outline, "Clients", colorScheme),
              _quickAction(Icons.straighten, "Measurements", colorScheme),
              _quickAction(
                Icons.design_services_outlined,
                "Designs",
                colorScheme,
              ),
              _quickAction(Icons.checkroom_outlined, "Closet", colorScheme),
              _quickAction(Icons.star_border, "Ratings", colorScheme),
            ],
          ),
          const SizedBox(height: 24),

          // 🎨 Featured Designs Carousel (placeholder)
          Text("Featured Designs", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "https://placehold.co/300x160.jpg",
                    width: 240,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 📊 Stats Grid
          Text("Your Stats", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statCard("Clients", "12", Icons.people, colorScheme, textTheme),
              _statCard(
                "Projects",
                "5",
                Icons.design_services,
                colorScheme,
                textTheme,
              ),
              _statCard("Pending", "3", Icons.schedule, colorScheme, textTheme),
            ],
          ),
          const SizedBox(height: 24),

          // 🕒 Recent Activity
          Text("Recent Activity", style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Column(
            children: List.generate(3, (index) {
              return ListTile(
                leading: const CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    "https://placehold.co/100.jpg",
                  ),
                ),
                title: Text("Client ${index + 1}"),
                subtitle: const Text("New measurement added"),
                trailing: const Icon(Icons.chevron_right),
              );
            }),
          ),
          const SizedBox(height: 24),

          // 👗 Closet Preview
          Text("Closet", style: textTheme.titleMedium),
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
                  child: CachedNetworkImage(
                    imageUrl: "https://placehold.co/100.jpg",
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

  // 🔹 Quick Action Widget
  Widget _quickAction(IconData icon, String label, ColorScheme scheme) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // 🔹 Stats Card
  Widget _statCard(
    String title,
    String value,
    IconData icon,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Expanded(
      child: Card(
        color: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 8),
              Text(value, style: textTheme.titleMedium),
              Text(title, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
