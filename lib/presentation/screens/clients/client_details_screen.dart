import 'package:fashionista/core/assets/app_images.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/client_measurement/client_measurement_screen.dart';
import 'package:fashionista/presentation/screens/clients/client_profile_page.dart';
import 'package:fashionista/presentation/screens/clients/edit_client_screen.dart';
import 'package:flutter/material.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;
  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  bool _isUploading = false;

  @override
  void initState() {
    _isUploading = false;
    super.initState();
  }

  @override
  @override
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const double maxAvatarRadius = 60;
    const double minAvatarRadius = 32;
    const double expandedHeight = 280;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: expandedHeight,
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                title: Text(
                  widget.client.fullName,
                  style: textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditClientScreen(client: widget.client),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final double shrinkOffset =
                        expandedHeight - constraints.maxHeight;
                    final double shrinkFactor =
                        (shrinkOffset / (expandedHeight - kToolbarHeight))
                            .clamp(0.0, 1.0);

                    final double avatarRadius =
                        maxAvatarRadius -
                        (maxAvatarRadius - minAvatarRadius) * shrinkFactor;
                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 56),
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: AppTheme.lightGrey,
                                    backgroundImage:
                                        widget.client.imageUrl != ''
                                        ? NetworkImage(widget.client.imageUrl!)
                                        : const AssetImage(AppImages.avatar)
                                              as ImageProvider,
                                  ),
                                  Positioned(
                                    bottom: 4, // slight overlap
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: colorScheme.onPrimary,
                                      child: IconButton(
                                        padding: EdgeInsets
                                            .zero, // removes default padding
                                        icon: Icon(
                                          Icons.camera_alt,
                                          size: 24,
                                          color: colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          // Handle camera click
                                          // _chooseImageSource(context);
                                        },
                                        splashRadius: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            //const SizedBox(height: 8),
                            // Hero(
                            //   tag: 'edit-client-button',
                            //   child: TextButton(
                            //     onPressed: () {
                            //       Navigator.push(
                            //         context,
                            //         MaterialPageRoute(
                            //           builder: (context) => EditClientScreen(
                            //             client: widget.client,
                            //           ),
                            //         ),
                            //       );
                            //     },
                            //     style: TextButton.styleFrom(
                            //       side: BorderSide(color: AppTheme.lightGrey),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //       padding: const EdgeInsets.symmetric(
                            //         horizontal: 8,
                            //         vertical: 6,
                            //       ),
                            //     ),
                            //     child: Text(
                            //       'Edit profile',
                            //       style: textTheme.bodyLarge,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                bottom: TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: AppTheme.darkGrey,
                  indicatorColor: colorScheme.primary,
                  dividerColor: AppTheme.lightGrey,
                  dividerHeight: 0,
                  indicatorWeight: 2,
                  indicator: UnderlineTabIndicator(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      width: 4,
                      color: colorScheme.primary,
                    ),
                    insets: EdgeInsets.symmetric(
                      horizontal: 36,
                    ), // adjust for fixed width
                  ),
                  tabs: [
                    Tab(text: "Profile"),
                    Tab(text: "Measurements"),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              ClientProfilePage(client: widget.client),
              ClientMeasurementScreen(client: widget.client),
            ],
          ),
        ),
      ),
    );
  }
}
