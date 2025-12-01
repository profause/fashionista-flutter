import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/custom_favourite_designer_icon_button.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
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
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final double radius = 60;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.only(
          //bottomLeft: Radius.circular(12),
          //bottomRight: Radius.circular(12),
        ),
        onTap:
            widget.onTap ??
            () {
              context.push('/designers/${widget.designerInfo.uid}');
            },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ✅ Banner expands full width of the Card
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: BannerImageWidget(
                          uid: widget.designerInfo.uid,
                          url: ValueNotifier(widget.designerInfo.bannerImage!),
                          isEditable: false,
                          height: 100,
                          // cover full area
                        ),
                      ),
                      // Profile image overlay
                      Positioned(
                        bottom: -(radius / 2),
                        left: 16,
                        child: Hero(
                          tag: widget.designerInfo.uid,
                          child: Material(
                            color: Colors.white,
                            borderOnForeground: true,
                            borderRadius: BorderRadius.circular(radius),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(radius),
                                onTap: () {},
                                child: widget.designerInfo.profileImage != ''
                                    ? CircleAvatar(
                                        radius: 30,
                                        backgroundColor: AppTheme.lightGrey,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                              widget.designerInfo.profileImage!,
                                              errorListener: (error) {},
                                            ),
                                      )
                                    : DefaultProfileAvatar(
                                        name: null,
                                        size: 60,
                                        uid: widget.designerInfo.uid,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            //CustomIconRounded(icon: Icons.person),
                            //const SizedBox(width: 8),
                            Text(
                              widget.designerInfo.name,
                              style: textTheme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacer(),
                            CustomFavouriteDesignerIconButton(
                              designerId: widget.designerInfo.uid,
                              isFavouriteNotifier: ValueNotifier(
                                widget.designerInfo.isFavourite!,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CustomIconRounded(icon: Icons.store),
                            const SizedBox(width: 8),
                            Text(
                              widget.designerInfo.businessName,
                              style: textTheme.bodyMedium!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: RatingInputWidget(
                            initialRating:
                                widget.designerInfo.averageRating ?? 0.0,
                            color: colorScheme.primary,
                            size: 24,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8, // 👈 reduced padding
                            children: widget.designerInfo.tags.isEmpty
                                ? [SizedBox(height: 1)]
                                : widget.designerInfo.tags
                                      .split('|')
                                      .where(
                                        (tag) => tag.trim().isNotEmpty,
                                      ) // ✅ only keep non-empty tags
                                      .map(
                                        (tag) => Chip(
                                          label: Text(tag),
                                          padding: EdgeInsets
                                              .zero, // remove extra padding
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                      .toList(),
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
