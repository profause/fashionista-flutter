
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/domain/usecases/designers/add_or_remove_favourite_usecase.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';

class DesignerInfoCardWidgetDiscoverPage extends StatefulWidget {
  final Designer designerInfo;
  final VoidCallback? onTap;
  const DesignerInfoCardWidgetDiscoverPage({
    super.key,
    required this.designerInfo,
    this.onTap,
  });

  @override
  State<DesignerInfoCardWidgetDiscoverPage> createState() =>
      _DesignerInfoCardWidgetDiscoverPageState();
}

class _DesignerInfoCardWidgetDiscoverPageState
    extends State<DesignerInfoCardWidgetDiscoverPage>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> isFavouriteNotifier = ValueNotifier(false);
  late AnimationController _controller;

  @override
  void initState() {
    isFavouriteNotifier.value = widget.designerInfo.isFavourite!;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    isFavouriteNotifier.addListener(() {
      if (isFavouriteNotifier.value) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final double radius = 55;
    return SizedBox(
      width: 160,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    height: 65,
                    // cover full area
                  ),
                ),
                // Profile image overlay
                Positioned(
                  bottom: -(radius / 2),
                  left: 50,
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
                                  radius: 24,
                                  backgroundColor: AppTheme.lightGrey,
                                  backgroundImage: CachedNetworkImageProvider(
                                    widget.designerInfo.profileImage!,
                                  ),
                                )
                              : DefaultProfileAvatar(
                                  name: null,
                                  size: 30,
                                  uid: widget.designerInfo.uid,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Column(
                children: [
                  Text(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    widget.designerInfo.name,
                    style: textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.designerInfo.businessName,
                    style: textTheme.bodyMedium!,
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<bool>(
                    valueListenable: isFavouriteNotifier,
                    builder: (_, isFavourite, _) {
                      return FilledButton(
                        onPressed: () async {
                          isFavouriteNotifier.value = !isFavourite;

                          final result = await sl<AddOrRemoveFavouriteUsecase>()
                              .call(widget.designerInfo.uid);
                          result.fold((l) {}, (r) {
                            isFavouriteNotifier.value = r;
                            setState(() {
                              isFavourite = r;
                            });
                          });
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          backgroundColor:
                              colorScheme.surface, // solid grey background
                          foregroundColor:
                              colorScheme.onSurface, // text/icon color
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            final inAnimation =
                                Tween<Offset>(
                                  begin: const Offset(0, 0.3), // slide up
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.bounceOut,
                                  ),
                                );

                            final outAnimation =
                                Tween<Offset>(
                                  begin: Offset.zero,
                                  end: const Offset(0, -0.3), // slide down
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.bounceIn,
                                  ),
                                );

                            // Separate animation for entering/exiting widgets
                            if (child.key == ValueKey(isFavourite)) {
                              return ClipRect(
                                child: SlideTransition(
                                  position: inAnimation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                              );
                            } else {
                              return ClipRect(
                                child: SlideTransition(
                                  position: outAnimation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            isFavourite ? "Following" : "Follow",
                            key: ValueKey(isFavourite),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
