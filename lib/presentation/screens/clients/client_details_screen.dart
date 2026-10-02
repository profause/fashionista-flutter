import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/client_measurement/client_measurement_screen.dart';
import 'package:fashionista/presentation/screens/clients/client_profile_page.dart';
import 'package:fashionista/presentation/screens/clients/client_project_page.dart';
import 'package:fashionista/presentation/screens/clients/edit_client_screen.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_pinned_client_icon_button.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId; // uid client;
  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const double expandedHeight = 230;
  late final TabController _tabController;
  bool _isDeletingClient = false;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    context.read<ClientBloc>().add(
      LoadClient(widget.clientId, isFromCache: true),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return BlocConsumer<ClientBloc, ClientBlocState>(
      listenWhen: (previous, current) =>
          _isDeletingClient &&
          (current is ClientDeleted || current is ClientError),
      listener: (context, state) {
        if (!_isDeletingClient || !mounted) return;

        _isDeletingClient = false;
        dismissLoadingDialog(context);

        if (state is ClientDeleted) {
          context.pop();
        } else if (state is ClientError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
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
            return Scaffold(
              backgroundColor: context.canvasBackground,
              body: NestedScrollView(
                physics: const ClampingScrollPhysics(),
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                context,
                              ),
                          sliver: SliverAppBar(
                            actions: [
                              CustomPinnedClientIconButton(client: client),
                              const SizedBox(width: 12),
                              CustomIconButtonRounded(
                                size: 18,
                                iconData: Icons.delete_outline,
                                //backgroundColor: context.canvasBackground,
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

                                  if (canDelete != true || !context.mounted) {
                                    return;
                                  }

                                  showLoadingDialog(context);
                                  await _deleteClient(client);
                                },
                              ),
                              const SizedBox(width: 12),
                              CustomIconButtonRounded(
                                size: 18,
                                iconData: Icons.edit_outlined,
                                //backgroundColor: context.canvasBackground,
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<ClientBloc>(),
                                        child: EditClientScreen(client: client),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                            ],
                            pinned: true,
                            floating: true,
                            //toolbarHeight: kToolbarHeight,
                            expandedHeight: expandedHeight,
                            backgroundColor: context.canvasBackground,
                            //foregroundColor: context.onCanvasText,
                            elevation: 0,
                            flexibleSpace: LayoutBuilder(
                              builder: (context, constraints) {
                                final percent =
                                    ((constraints.maxHeight - kToolbarHeight) /
                                            (expandedHeight - kToolbarHeight))
                                        .clamp(
                                          0.0,
                                          1.0,
                                        ); // scroll progress 0..1

                                final avatarSize = 56 + (68 - 56) * percent;
                                return FlexibleSpaceBar(
                                  collapseMode: CollapseMode.parallax,
                                  background: SafeArea(
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 32),
                                        _buildProfileHeader(client, avatarSize),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            bottom: TabBar(
                              controller: _tabController,
                              labelColor: context.onCanvasText,
                              unselectedLabelColor: context.mutedText,
                              indicatorColor: context.accent,
                              dividerColor: context.hairline,
                              physics: const BouncingScrollPhysics(),
                              dividerHeight: 1,
                              indicatorWeight: 2,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabs: [
                                Tab(
                                  icon: Icon(Icons.person_2, size: 20),
                                  text: 'Info',
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.straighten_rounded,
                                    size: 20,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Measurements',
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                                Tab(
                                  icon: Icon(Icons.work_history, size: 20),
                                  text: 'Orders',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                body: TabBarView(
                  controller: _tabController, // ✅ connect the same controller
                  children: [
                    Builder(
                      builder: (context) {
                        return CustomScrollView(
                          // Let this scroll work with NestedScrollView
                          key: PageStorageKey("client"),
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            ClientProfilePage(client: client),
                          ],
                        );
                      },
                    ),

                    Builder(
                      builder: (context) {
                        return CustomScrollView(
                          // Let this scroll work with NestedScrollView
                          key: PageStorageKey("client"),
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            ClientMeasurementScreen(client: client),
                          ],
                        );
                      },
                    ),

                    Builder(
                      builder: (context) {
                        return CustomScrollView(
                          // Let this scroll work with NestedScrollView
                          key: PageStorageKey("client"),
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            ClientProjectPage(client: client),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileHeader(Client client, double avatarSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DefaultProfileAvatar(
              name: null,
              size: avatarSize * 1.3,
              uid: client.uid,
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.accent,
                  border: Border.all(color: context.canvasBackground, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.hairline)),
      ),
      child: TabBar(
        labelColor: context.accent,
        unselectedLabelColor: context.mutedText,
        indicatorColor: context.accent,
        dividerColor: context.hairline,
        dividerHeight: 0,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.person_2, size: 20), text: 'Info'),
          Tab(
            icon: Icon(Icons.straighten_rounded, size: 20),
            text: 'Measurements',
          ),
          Tab(icon: Icon(Icons.work_history, size: 20), text: 'Orders'),
        ],
      ),
    );
  }

  Future<void> _deleteClient(Client client) async {
    if (_isDeletingClient) return;

    _isDeletingClient = true;
    context.read<ClientBloc>().add(DeleteClient(client.uid));
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
