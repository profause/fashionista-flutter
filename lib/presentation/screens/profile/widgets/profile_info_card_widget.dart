import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class ProfileInfoCardWidget extends StatelessWidget {
  final List<ProfileInfoItem> items;

  const ProfileInfoCardWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        ////border: Border.all(color: context.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Divider(
              height: 1,
              thickness: 1,
              color: context.hairline,
              indent: 56,
              endIndent: 12,
            );
          }

          final item = items[index ~/ 2];
          return _ProfileInfoRow(item: item);
        }),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final ProfileInfoItem item;
  const _ProfileInfoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final IconData? icon = item.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.iconSubstrate,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: context.secondaryLabel),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: item.value.isEmpty
                ? Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.title.isNotEmpty) ...[
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: context.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
          if (item.suffix != null) ...[const SizedBox(width: 8), item.suffix!],
        ],
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