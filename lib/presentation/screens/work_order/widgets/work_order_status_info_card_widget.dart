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
      borderRadius: BorderRadius.circular(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  // Timestamp
                  Tooltip(
                    message: workOrderStatusInfo.createdAt.toString(),
                    child: Text(
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      formatRelativeTime(workOrderStatusInfo.createdAt!)
                          .trim(),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isFirst
                            ? const Color(0xFFFF5A00)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Node circle
                  Container(
                    width: isFirst ? 14 : 10,
                    height: isFirst ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst
                          ? const Color(0xFFFF5A00)
                          : colorScheme.onSurface.withValues(alpha: 0.25),
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: isFirst
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF5A00,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: colorScheme.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isFirst) ...[
                                // "In Progress" chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFF0E6,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF5A00,
                                      ).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: const Text(
                                    'In Progress',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF5A00),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 9),
                              ],
                              Tooltip(
                                message: workOrderStatusInfo
                                    .status, // 👈 shows full text
                                child: Text(
                                  workOrderStatusInfo.status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                workOrderStatusInfo.description ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium!.copyWith(
                                  fontSize: 12.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (onDelete != null)
                          CustomIconButtonRounded(
                            onPressed: () => onDelete?.call(),
                            iconData: Icons.delete,
                            size: 16,
                          ),
                      ],
                    ),
                    if (previewImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 154,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          //padding: const EdgeInsets.only(top: 2, bottom: 4),
                          itemCount: previewImages.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final image = previewImages[index];
                            return Container(
                              width: 112,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                //border: Border.all(
                                //  color: colorScheme.onSurface.withValues(alpha: 0.08),
                                //),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
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
                                  // Scrim for readability of label chip
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.45),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
