import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/presentation/screens/client_measurement/client_measurement_screen.dart';
import 'package:fashionista/presentation/screens/clients/client_profile_page.dart';
import 'package:fashionista/presentation/screens/clients/client_project_page.dart';
import 'package:fashionista/presentation/screens/clients/edit_client_screen.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_pinned_client_icon_button.dart';
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
  static const double expandedHeight = 250;

  @override
  void initState() {
    context.read<ClientBloc>().add(UpdateClient(widget.client));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<ClientBloc, ClientBlocState>(
      buildWhen: (context, state) {
        return state is ClientLoaded || state is ClientUpdated;
      },
      builder: (context, state) {
        switch (state) {
          case ClientDeleted():
            if (mounted) {
              Navigator.pop(context);
            }
            break;
          case ClientLoaded(:final client):
          case ClientUpdated(:final client):
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
                        backgroundColor: colorScheme.onPrimary,
                        foregroundColor: colorScheme.primary,
                        elevation: 0,
                        title: Text(
                          client.fullName,
                          style: textTheme.titleLarge!,
                        ),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.only(right: 18),
                            child: Row(
                              children: [
                                CustomPinnedClientIconButton(
                                  clientId: widget.client.uid,
                                  isPinnedNotifier: ValueNotifier(
                                    widget.client.isPinned ?? false,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // DELETE
                                CustomIconButtonRounded(
                                  size: 20,
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
                                          barrierDismissible: false,
                                          builder: (_) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      await _deleteClient(client);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                // EDIT
                                CustomIconButtonRounded(
                                  size: 20,
                                  iconData: Icons.edit,
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<ClientBloc>(),
                                          child: EditClientScreen(
                                            client: client,
                                          ),
                                        ),
                                      ),
                                    );

                                    // if (result == true && mounted) {
                                    //   Navigator.pop(context, true); // notify ClientsScreen
                                    // }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.parallax,
                          background: SafeArea(
                            child: Column(
                              children: [
                                const SizedBox(height: 56),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      DefaultProfileAvatar(
                                        name: null,
                                        size: 120,
                                        uid: client.uid,
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              colorScheme.onPrimary,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              Icons.camera_alt,
                                              color: colorScheme.primary,
                                              size: 24,
                                            ),
                                            onPressed: () {
                                              // TODO: implement image change
                                            },
                                            splashRadius: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                //
                              ],
                            ),
                          ),
                        ),
                        bottom: TabBar(
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: AppTheme.darkGrey,
                          indicatorColor: AppTheme.appIconColor.withValues(alpha: 1),
                          dividerColor: AppTheme.lightGrey,
                          dividerHeight: 0,
                          indicatorWeight: 2,
                          indicator: UnderlineTabIndicator(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              width: 4,
                              color: AppTheme.appIconColor.withValues(alpha: 1),
                            ),
                          ),
                          tabs: [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              child: Icon(
                                Icons.person_2,
                                size: 22,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              child: Icon(
                                Icons.straighten_rounded,
                                size: 22,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              child: Icon(
                                Icons.work_history,
                                size: 22,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      ClientProfilePage(client: client),
                      ClientMeasurementScreen(client: client),
                      ClientProjectPage(client: client),
                    ],
                  ),
                ),
              ),
            );
        }
        return const SizedBox.shrink();
      },
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
          Navigator.of(context, rootNavigator: true).pop(); // remove loader
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop(); // remove loader
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(r)));
          Navigator.pop(context, true); // notify ClientsScreen
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }
}
