import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/screens/designers/designer_collection_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_details_profile_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_feedback_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_highlights_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_profile_page.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/custom_favourite_designer_icon_button.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DesignerDetailsScreen extends StatefulWidget {
  final Designer designer;
  const DesignerDetailsScreen({super.key, required this.designer});

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
    const double expandedHeight = 200;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: false,
                expandedHeight: expandedHeight,
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                //title: Text(user.fullName, style: textTheme.labelLarge!),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Row(
                      children: [
                        CustomFavouriteDesignerIconButton(
                          designerId: widget.designer.uid,
                          isFavouriteNotifier: ValueNotifier(
                            widget.designer.isFavourite!,
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
                        (shrinkOffset / (expandedHeight - kToolbarHeight))
                            .clamp(0.0, 1.0);
                    double avatarRadius =
                        maxAvatarRadius -
                        (maxAvatarRadius - minAvatarRadius) * shrinkFactor;
                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Banner image
                          BannerImageWidget(
                            uid: widget.designer.uid,
                            url: ValueNotifier(widget.designer.bannerImage!),
                            isEditable: false,
                          ),
                          Positioned(
                            top: (expandedHeight / 2) + (avatarRadius / 6),
                            left: 16,
                            child: Hero(
                              tag: widget.designer.uid,
                              child: buildProfileAvatar(
                                avatarRadius,
                                widget.designer,
                              ),
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
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: AppTheme.darkGrey,
                    indicatorColor: colorScheme.primary,
                    dividerColor: AppTheme.lightGrey,
                    dividerHeight: 0,
                    indicatorWeight: 2,
                    tabAlignment: TabAlignment.center,
                    labelPadding: const EdgeInsets.all(0),
                    //padding: const EdgeInsets.all(64),
                    isScrollable: true,
                    indicator: UnderlineTabIndicator(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        width: 4,
                        color: colorScheme.primary,
                      ),
                      // insets: EdgeInsets.symmetric(
                      //   horizontal: 60,
                      // ), // adjust for fixed width
                    ),
                    tabs: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        // divider color
                        child: Text(
                          "Details",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        // divider color
                        child: Text(
                          "Collections",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                      Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        // divider color
                        child: Text(
                          "Highlights",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        // divider color
                        child: Text(
                          "Feedback",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              DesignerDetailsProfilePage(designer: widget.designer),
              DesignerCollectionPage(designer: widget.designer),
              DesignerHighlightsPage(),
              DesignerFeedbackPage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProfileAvatar(double radius, Designer designer) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
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
                      backgroundColor: AppTheme.lightGrey,
                      backgroundImage: CachedNetworkImageProvider(
                        designer.profileImage!,
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
