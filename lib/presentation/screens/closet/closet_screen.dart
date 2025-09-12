import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/outfit_planner_screen.dart';
import 'package:fashionista/presentation/screens/closet/outfits_page.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  static const double expandedHeight = 168;
  late UserBloc userBloc;

  @override
  void initState() {
    userBloc = context.read<UserBloc>();
    getItemsCountFromCloset();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      // ✅ Provide TabController
      length: 3, // Items, Outfits, Planner
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              /// Profile AppBar
              SliverAppBar(
                pinned: true,
                toolbarHeight: 0,
                expandedHeight: expandedHeight,
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                flexibleSpace: BlocBuilder<UserBloc, User>(
                  builder: (context, user) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final percent =
                            ((constraints.maxHeight - kToolbarHeight) /
                                    (expandedHeight - kToolbarHeight))
                                .clamp(0.0, 1.0); // scroll progress 0..1

                        final avatarSize = 56 + (68 - 56) * percent;
                        return FlexibleSpaceBar(
                          collapseMode: CollapseMode.parallax,
                          background: SafeArea(
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Material(
                                        color: Colors.white,
                                        borderOnForeground: true,
                                        borderRadius: BorderRadius.circular(60),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            onTap: () {},
                                            child: user.profileImage.isNotEmpty
                                                ? CircleAvatar(
                                                    radius:
                                                        avatarSize /
                                                        2, // ✅ shrink smoothly
                                                    backgroundColor:
                                                        AppTheme.lightGrey,
                                                    backgroundImage:
                                                        CachedNetworkImageProvider(
                                                          user.profileImage,
                                                        ),
                                                  )
                                                : DefaultProfileAvatar(
                                                    name: null,
                                                    size: avatarSize,
                                                    uid: user.uid!,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Opacity(
                                  opacity:
                                      percent, // ✅ fade name out as it collapses
                                  child: Text(
                                    "My Closet",
                                    style: textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                //
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                bottom: TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: AppTheme.darkGrey,
                  indicatorColor: colorScheme.primary,
                  dividerColor: AppTheme.lightGrey,
                  physics: const BouncingScrollPhysics(),
                  dividerHeight: 0,
                  indicatorWeight: 2,
                  indicatorPadding: const EdgeInsets.only(left: 8, right: 8),
                  indicator: UnderlineTabIndicator(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      width: 4,
                      color: colorScheme.primary,
                    ),
                  ),
                  tabs: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Items",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800] // dark mode background
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$_closetItemCount",
                              style: textTheme.labelSmall!.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Outfits",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800] // dark mode background
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$_outfitCount",
                              style: textTheme.labelSmall!.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Planner",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // const SizedBox(width: 4),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //     vertical: 0,
                          //     horizontal: 4,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     color: Colors.grey[300],
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: Text("000", style: textTheme.labelSmall!),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },

          /// TabBarView = main body
          body: const TabBarView(
            children: [ClosetItemsPage(), OutfitsPage(), OutfitPlannerScreen()],
          ),
        ),
      ),
    );
  }

  int _closetItemCount = 0;
  int _outfitCount = 0;

  Future<void> getItemsCountFromCloset() async {
    try {
      final results = await Future.wait([
        sl<FirebaseClosetService>().getClosetItemCount(userBloc.state.uid!),
        sl<FirebaseClosetService>().getOutfitCount(userBloc.state.uid!),
      ]);

      // Unwrap results
      final itemCount = results[0].fold(
        (l) => 0,
        (r) => r,
      ); // return 0 on failure
      final outfitCount = results[1].fold((l) => 0, (r) => r);

      setState(() {
        _closetItemCount = itemCount;
        _outfitCount = outfitCount;
      });
    } catch (e) {
      debugPrint("Error loading closet counts: $e");
    }
  }
}
