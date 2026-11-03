import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_service_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card that summarises a designer service with edit/delete actions.
class DesignerServiceCardWidget extends StatelessWidget {
  final DesignerServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const DesignerServiceCardWidget({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tags = service.tagList;
    final description = service.description?.trim() ?? '';
    final updatedAt = service.updatedAt;
    final cover = service.coverImage;

    final priceLabel = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    ).format(service.price).trim();

    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cover != null) _buildCover(context, cover),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service.name.isEmpty
                              ? 'Untitled service'
                              : service.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: context.onCanvasText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        priceLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.accent,
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.secondaryButtonBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: context.hairline),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.onCanvasText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1, color: context.hairline),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.update, size: 13, color: context.mutedText),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          updatedAt == null
                              ? 'Not updated yet'
                              : 'Updated ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(updatedAt))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomIconButtonRounded(
                        iconData: Icons.edit_outlined,
                        size: 16,
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      CustomIconButtonRounded(
                        iconData: Icons.delete_outline,
                        size: 16,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cover image shown at the top of the card, using the first featured image.
  Widget _buildCover(BuildContext context, FeaturedMediaModel cover) {
    final rawAspect = cover.aspectRatio;
    final aspectRatio = (rawAspect == null || rawAspect <= 0)
        ? 16 / 9
        : rawAspect.clamp(1.2, 2.4).toDouble();

    final thumbnail = cover.thumbnailUrl?.trim() ?? '';
    final imageUrl = thumbnail.isNotEmpty ? thumbnail : (cover.url ?? '');
    final imageCount = service.featuredImages.length;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: imageUrl.isEmpty
              ? Container(color: context.secondaryButtonBg)
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: context.secondaryButtonBg),
                  errorWidget: (_, _, _) => Container(
                    color: context.secondaryButtonBg,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: context.mutedText,
                    ),
                  ),
                ),
        ),
        if (imageCount > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$imageCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
