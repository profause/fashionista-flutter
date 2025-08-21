import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase_clients_service.dart';
import 'package:fashionista/presentation/screens/client_measurement/client_measurement_screen.dart';
import 'package:fashionista/presentation/screens/clients/client_profile_page.dart';
import 'package:fashionista/presentation/screens/clients/edit_client_screen.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;
  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
// bool _isUploading = false;

  @override
  void initState() {
   // _isUploading = false;
    context.read<ClientCubit>().updateClient(widget.client);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const double maxAvatarRadius = 60;
    const double minAvatarRadius = 32;
    const double expandedHeight = 250;

    return DefaultTabController(
      length: 2,
      child: BlocBuilder<ClientCubit, ClientState>(
        builder: (context, state) {
          if (state is ClientLoaded || state is ClientUpdated) {
            return Scaffold(
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
                        state.client.fullName,
                        style: textTheme.titleLarge!,
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: Row(
                            children: [
                              CustomIconButtonRounded(
                                size: 24,
                                iconData: Icons.delete,
                                onPressed: () async {
                                  final canDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Client'),
                                      content: const Text(
                                        'Are you sure you want to delete this client?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                          
                                  if (canDelete == true) {
                                    if (mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible:
                                            false, // Prevent dismissing
                                        builder: (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    _deleteClient(state.client);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              CustomIconButtonRounded(
                                size: 24,
                                iconData: Icons.edit,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context
                                            .read<
                                              ClientCubit
                                            >(), // reuse existing cubit
                                        child: EditClientScreen(
                                          client: state.client,
                                        ),
                                      ),
                                    ),
                                  );
                          
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) =>
                                  //         EditClientScreen(client: state.client),
                                  //   ),
                                  // );
                                },
                              ),
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

                          final double avatarRadius =
                              maxAvatarRadius -
                              (maxAvatarRadius - minAvatarRadius) *
                                  shrinkFactor;
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
                                        DefaultProfileAvatar(name:null,size: 120,uid:state.client.uid,),
                                        // CircleAvatar(
                                        //   radius: avatarRadius,
                                        //   backgroundColor: AppTheme.lightGrey,
                                        //   backgroundImage: CachedNetworkImageProvider(state.client.imageUrl!),
                                        // ),
                                        Positioned(
                                          bottom: 4, // slight overlap
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                colorScheme.onPrimary,
                                            child: IconButton(
                                              padding: EdgeInsets
                                                  .zero, // removes default padding
                                              icon: Icon(
                                                Icons.camera_alt,
                                                size: 24,
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
                            horizontal: 50,
                          ), // adjust for fixed width
                        ),
                        tabs: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            // divider color
                            child: Text(
                              "Profile",
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          //Tab(text: "Profile"),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            // divider color
                            child: Text(
                              "Measurements",
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    ClientProfilePage(client: state.client),
                    ClientMeasurementScreen(client: state.client),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<void> _deleteClient(Client client) async {
    try {
      final result = await sl<FirebaseClientsService>().deleteClientById(
        client.uid,
      );
      result.fold(
        (l) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          if (!mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(r)));
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.pop(context);
        },
      );
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }
}
