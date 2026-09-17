import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/custom_favourite_designer_icon_button.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesignerInfoCardWidget extends StatefulWidget {
  final Designer designerInfo;
  final VoidCallback? onTap;
  const DesignerInfoCardWidget({
    super.key,
    required this.designerInfo,
    this.onTap,
  });

  @override
  State<DesignerInfoCardWidget> createState() => _DesignerInfoCardWidgetState();
}

class _DesignerInfoCardWidgetState extends State<DesignerInfoCardWidget> {
  static const double _avatarRadius = 32;

  void _openDesigner() {
    context.push('/designers/${widget.designerInfo.uid}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final designer = widget.designerInfo;
    final tags = designer.tags
        .split('|')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap ?? _openDesigner,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 144,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BannerImageWidget(
                        uid: designer.uid,
                        url: ValueNotifier(designer.bannerImage ?? ''),
                        isEditable: false,
                        height: 144,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -_avatarRadius,
                  left: 16,
                  child: Hero(
                    tag: designer.uid,
                    child: Material(
                      color: context.cardSurface,
                      borderOnForeground: true,
                      borderRadius: BorderRadius.circular(_avatarRadius),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: designer.profileImage != null &&
                                  designer.profileImage!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: designer.profileImage!,
                                  width: _avatarRadius * 2,
                                  height: _avatarRadius * 2,
                                  fit: BoxFit.cover,
                                  errorListener: (_) {},
                                  errorWidget: (_, _, _) =>
                                      DefaultProfileAvatar(
                                    name: null,
                                    size: _avatarRadius * 2,
                                    uid: designer.uid,
                                  ),
                                )
                              : DefaultProfileAvatar(
                                  name: null,
                                  size: _avatarRadius * 2,
                                  uid: designer.uid,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -36,
                  right: 12,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.iconSubstrate,
                      shape: BoxShape.circle,
                      //border: Border.all(color: context.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CustomFavouriteDesignerIconButton(
                      designerId: designer.uid,
                      isFavouriteNotifier: ValueNotifier(
                        designer.isFavourite ?? false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          designer.name,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (designer.averageRating != null) ...[
                        Icon(Icons.star, color: Colors.amber.shade500, size: 18),
                        const SizedBox(width: 2),
                        Text(
                          designer.averageRating!.toStringAsFixed(1),
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (designer.reviewCount != null) ...[
                        const SizedBox(width: 2),
                        Text(
                          '(${designer.reviewCount})',
                          style: textTheme.bodySmall!.copyWith(
                            color: context.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.storefront, size: 16, color: context.mutedText),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          designer.businessName.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall!.copyWith(
                            color: context.mutedText,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (designer.location.isNotEmpty) ...[
                        Text(
                          '  •  ',
                          style: textTheme.labelSmall!
                              .copyWith(color: context.hairline),
                        ),
                        Text(
                          designer.location,
                          style: textTheme.labelSmall!
                              .copyWith(color: context.mutedText),
                        ),
                      ],
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in tags) _SpecialtyChip(label: tag),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.hairline),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _openDesigner,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: context.accent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.accent
                                        .withValues(alpha: 0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Book Consultation',
                                    style: textTheme.labelLarge!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _openDesigner,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.canvasBackground,
                              borderRadius: BorderRadius.circular(12),
                              //border: Border.all(color: context.hairline),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                              color: context.onCanvasText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  const _SpecialtyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.iconSubstrate,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: context.descriptionText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}