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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId; // uid client;
  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  @override
  void initState() {
    context.read<ClientBloc>().add(
      LoadClient(widget.clientId, isFromCache: true),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: context.canvasBackground,
                appBar: AppBar(
                  backgroundColor: context.canvasBackground,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  title: const SizedBox.shrink(),
                  actions: [
                    const SizedBox(width: 8),
                    CustomPinnedClientIconButton(client: client),
                    const SizedBox(width: 8),
                    CustomIconButtonRounded(
                      size: 20,
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

                        if (canDelete == true) {
                          if (mounted) {
                            showLoadingDialog(context);
                          }
                          await _deleteClient(client);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    CustomIconButtonRounded(
                      size: 20,
                      iconData: Icons.edit_outlined,
                      //backgroundColor: context.canvasBackground,
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
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                body: Column(
                  children: [
                    _buildProfileHeader(client),
                    _buildSegmentedTabs(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ClientProfilePage(client: client),
                          ClientMeasurementScreen(client: client),
                          ClientProjectPage(client: client),
                        ],
                      ),
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

  Widget _buildProfileHeader(Client client) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.iconSubstrate,
                border: Border.all(
                  color: context.canvasBackground,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 48,
                color: context.mutedText,
              ),
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
                  border: Border.all(
                    color: context.canvasBackground,
                    width: 2,
                  ),
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
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.person_2, size: 20), text: 'Info'),
          Tab(icon: Icon(Icons.straighten_rounded, size: 20), text: 'Measurements'),
          Tab(icon: Icon(Icons.work_history, size: 20), text: 'Orders'),
        ],
      ),
    );
  }

  Future<void> _deleteClient(Client client) async {
    context.read<ClientBloc>().add(DeleteClient(client.uid));
    if (!mounted) return;
    dismissLoadingDialog(context);
    context.pop();
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
