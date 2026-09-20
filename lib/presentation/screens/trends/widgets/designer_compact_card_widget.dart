import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/domain/usecases/designers/add_or_remove_favourite_usecase.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Compact designer card (130x170) used by the "Designers" row on the
/// For You tab (Stitch: avatar, name, brand and a full width follow button).
class DesignerCompactCardWidget extends StatefulWidget {
  const DesignerCompactCardWidget({
    super.key,
    required this.designerInfo,
    this.onFollowTap,
  });

  final Designer designerInfo;
  final Function(bool)? onFollowTap;

  @override
  State<DesignerCompactCardWidget> createState() =>
      _DesignerCompactCardWidgetState();
}

class _DesignerCompactCardWidgetState extends State<DesignerCompactCardWidget> {
  final ValueNotifier<bool> isFavouriteNotifier = ValueNotifier(false);

  @override
  void initState() {
    isFavouriteNotifier.value = widget.designerInfo.isFavourite ?? false;
    super.initState();
  }

  @override
  void dispose() {
    isFavouriteNotifier.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow() async {
    isFavouriteNotifier.value = !isFavouriteNotifier.value;

    final result = await sl<AddOrRemoveFavouriteUsecase>().call(
      widget.designerInfo.uid,
    );

    result.fold((failure) {}, (isFavourite) {
      if (!mounted) return;
      isFavouriteNotifier.value = isFavourite;
      widget.onFollowTap?.call(isFavourite);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String imageUrl = widget.designerInfo.profileImage ?? '';

    return SizedBox(
      width: 130,
      height: 170,
      child: Material(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/designers/${widget.designerInfo.uid}'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.hairline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: imageUrl.isEmpty
                        ? DefaultProfileAvatar(
                            name: widget.designerInfo.name,
                            size: 56,
                            uid: widget.designerInfo.uid,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorListener: (error) {},
                            placeholder: (_, _) => DefaultProfileAvatar(
                              name: widget.designerInfo.name,
                              size: 56,
                              uid: widget.designerInfo.uid,
                            ),
                            errorWidget: (_, _, _) => DefaultProfileAvatar(
                              name: widget.designerInfo.name,
                              size: 56,
                              uid: widget.designerInfo.uid,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        widget.designerInfo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.designerInfo.businessName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                          height: 1.2,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isFavouriteNotifier,
                  builder: (context, isFavourite, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: Material(
                        color: isFavourite
                            ? context.secondaryButtonBg
                            : context.accent,
                        borderRadius: BorderRadius.circular(999),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _toggleFollow,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: isFavourite
                                  ? Border.all(color: context.softBorder)
                                  : null,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                isFavourite ? 'Following' : 'Follow',
                                key: ValueKey<bool>(isFavourite),
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0,
                                  color: isFavourite
                                      ? context.onCanvasText
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
