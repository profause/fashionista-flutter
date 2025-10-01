import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';

class WorkOrderStatusInfoCardWidget extends StatelessWidget {
  final WorkOrderStatusProgressModel workOrderStatusInfo;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isLast;
  final bool isFirst;

  const WorkOrderStatusInfoCardWidget({
    super.key,
    required this.workOrderStatusInfo,
    this.onTap,
    this.isLast = false,
    required this.isFirst,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final previewImages = workOrderStatusInfo.featuredMedia!
        .map((e) => e.url)
        .toList();
    return InkWell(
      onTap: onTap, // ✅ triggers the callback when tapped
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          //color: colorScheme.onPrimary,
          //borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textAlign: TextAlign.center,
                formatRelativeTime(workOrderStatusInfo.createdAt!).trim(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  // Circle
                  Container(
                    width: 16,
                    height: 16,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),

                  // Vertical line (hidden if last)
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //const Divider(height: .1, thickness: .1),
                      //const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // 👈 aligns items to the top
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workOrderStatusInfo.status,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                workOrderStatusInfo.description ?? '',
                                style: textTheme.bodyMedium!.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          CustomIconButtonRounded(
                            backgroundColor: colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                            onPressed: () {
                              onDelete!();
                            },
                            iconData: Icons.delete,
                            size: 18,
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(
                            right: 8,
                            top: 8,
                            bottom: 8,
                          ),
                          itemCount: previewImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final image = previewImages[index];
                            return AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: image!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const CustomColoredBanner(text: ''),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
