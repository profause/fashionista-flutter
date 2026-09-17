import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/screens/designers/designer_collection_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_details_profile_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_review_page.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/custom_favourite_designer_icon_button.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerDetailsScreen extends StatefulWidget {
  final String designerId;
  const DesignerDetailsScreen({super.key, required this.designerId});

  @override
  State<DesignerDetailsScreen> createState() => _DesignerDetailsScreenState();
}

class _DesignerDetailsScreenState extends State<DesignerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Show status bar, hide navigation bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top], // keep only status bar
    );

    final bloc = context.read<DesignerBloc>();
    final currentState = bloc.state;
    Designer? preloaded;
    if (currentState is DesignerLoaded &&
        currentState.designer.uid == widget.designerId) {
      preloaded = currentState.designer;
    } else if (currentState is DesignersLoaded) {
      for (final designer in currentState.designers) {
        if (designer.uid == widget.designerId) {
          preloaded = designer;
          break;
        }
      }
    }

    if (preloaded != null) {
      bloc.add(UpdateDesigner(preloaded));
    }

    bloc.add(LoadDesigner(widget.designerId, isFromCache: true));
  }

  @override
  void dispose() {
    // Restore system UI when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    const double maxAvatarRadius = 40;
    const double minAvatarRadius = 32;
    //const double avatarRadius = 40;
    const double expandedHeight = 220;
    return BlocBuilder<DesignerBloc, DesignerState>(
      buildWhen: (context, state) {
        return state is DesignerLoaded || state is DesignerUpdated;
      },
      builder: (context, state) {
        switch (state) {
          case DesignerLoaded(:final designer):
          case DesignerUpdated(:final designer):
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                backgroundColor: colorScheme.surface,
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        pinned: true,
                        expandedHeight: expandedHeight,
                        foregroundColor: colorScheme.onSurface,
                        backgroundColor: colorScheme.surface,
                        elevation: 0,
                        //title: Text(user.fullName, style: textTheme.labelLarge!),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.only(right: 18),
                            child: Row(
                              children: [
                                CustomFavouriteDesignerIconButton(
                                  designerId: widget.designerId,
                                  isFavouriteNotifier: ValueNotifier(
                                    designer.isFavourite!,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ],
                        flexibleSpace: LayoutBuilder(
                          builder: (context, constraints) {
                            final double shrinkOffset =
                                expandedHeight - constraints.maxHeight;
                            final double shrinkFactor =
                                (shrinkOffset /
                                        (expandedHeight - kToolbarHeight))
                                    .clamp(0.0, 1.0);
                            double avatarRadius =
                                maxAvatarRadius -
                                (maxAvatarRadius - minAvatarRadius) *
                                    shrinkFactor;
                            final double? averageRating =
                                designer.averageRating;
                            final int? reviewCount = designer.reviewCount;
                            return FlexibleSpaceBar(
                              collapseMode: CollapseMode.parallax,
                              background: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Banner image
                                  BannerImageWidget(
                                    uid: designer.uid,
                                    url: ValueNotifier(designer.bannerImage!),
                                    isEditable: false,
                                  ),
                                  Positioned(
                                    top:
                                        (expandedHeight / 3) +
                                        (avatarRadius / 1.2),
                                    left: 16,
                                    child: Hero(
                                      tag: designer.uid,
                                      child: buildProfileAvatar(
                                        avatarRadius,
                                        designer,
                                      ),
                                    ),
                                  ),

                                  Positioned(
                                    bottom: 45,
                                    left: 16,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (averageRating != null) ...[
                                          _InfoPill(
                                            icon: Icons.star_rounded,
                                            iconColor: context.accent,
                                            label:
                                                '${averageRating.toStringAsFixed(1)}'
                                                '${reviewCount != null && reviewCount > 0 ? ' ($reviewCount reviews)' : ''}',
                                          ),
                                        ],
                                        if (designer.location.isNotEmpty) ...[
                                          _InfoPill(
                                            icon: Icons.location_on_outlined,
                                            iconColor: context.secondaryLabel,
                                            label: designer.location,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(
                            0,
                          ), // set your desired height
                          child: TabBar(
                            labelColor: context.accent,
                            unselectedLabelColor: context.mutedText,
                            indicatorColor: context.accent,
                            dividerColor: context.hairline,
                            dividerHeight: 1,
                            indicatorWeight: 4,
                            indicatorSize: TabBarIndicatorSize.label,
                            isScrollable: true,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            tabAlignment: TabAlignment.center,
                            labelStyle: textTheme.titleSmall!.copyWith(
                              //fontWeight: FontWeight.w500,
                            ),
                            tabs: const [
                              Tab(text: 'About'),
                              Tab(text: 'Highlights & Collections'),
                              Tab(text: 'Reviews'),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      DesignerDetailsProfilePage(designer: designer),
                      DesignerCollectionPage(designer: designer),
                      DesignerReviewPage(designer: designer),
                    ],
                  ),
                ),
              ),
            );
        }
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget buildProfileAvatar(double radius, Designer designer) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: colorScheme.surface,
          borderOnForeground: true,
          borderRadius: BorderRadius.circular(60),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: () {},
              child: designer.profileImage != ''
                  ? CircleAvatar(
                      radius: radius,
                      backgroundColor: colorScheme.surfaceContainerLow,
                      backgroundImage: CachedNetworkImageProvider(
                        designer.profileImage!,
                        errorListener: (error) {},
                      ),
                    )
                  : DefaultProfileAvatar(
                      name: null,
                      size: radius * 1.8,
                      uid: designer.uid,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _InfoPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(999),
          //border: Border.all(color: context.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.copyWith(color: context.onCanvasText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
