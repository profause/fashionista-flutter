import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/presentation/screens/client_measurement/add_client_measurement_screen.dart';
import 'package:fashionista/presentation/screens/client_measurement/measurement_info_card_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientMeasurementScreen extends StatefulWidget {
  final Client client;
  const ClientMeasurementScreen({super.key, required this.client});

  @override
  State<ClientMeasurementScreen> createState() =>
      _ClientMeasurementScreenState();
}

class _ClientMeasurementScreenState extends State<ClientMeasurementScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = "";
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    //context.read<ClientBloc>().add(UpdateClient(widget.client));
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
            final filteredMeasurements = _searchText.isEmpty
                ? client.measurements
                : client.measurements.where((m) {
                    final bodyPart = m.bodyPart.toLowerCase();
                    return bodyPart.contains(_searchText.toLowerCase());
                  }).toList();
            return Scaffold(
              backgroundColor: context.canvasBackground,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _searchFocusNode.hasFocus
                              ? context.accent.withValues(alpha: 0.7)
                              : context.hairline,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 16,
                            color: context.mutedText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: const ValueKey("searchField"),
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search measurements...',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: context.placeholderText,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: context.onCanvasText,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isSearching = value.isNotEmpty;
                                  _searchText = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        if (filteredMeasurements.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                'No measurements found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.mutedText,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: context.cardSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.hairline),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < filteredMeasurements.length;
                                  i++
                                ) ...[
                                  if (i > 0)
                                    Container(
                                      height: 1,
                                      color: context.hairline,
                                    ),
                                  _buildMeasurementRow(
                                    client,
                                    filteredMeasurements[i],
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: Hero(
                tag: 'add-measurement-button',
                child: Material(
                  color: context.accent,
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x61FF5A00),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value:
                                  context
                                      .read<ClientBloc>(), // reuse existing cubit
                              child: AddClientMeasurementScreen(
                                clientMeasurement: ClientMeasurement.empty(),
                                client: client,
                              ),
                            ),
                          ),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildMeasurementRow(
    Client client,
    ClientMeasurement measurement,
  ) {
    return MeasurementInfoCardWidget(
      client: client,
      measurement: measurement,
      onDelete: () async {
        final canDelete = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Measurement'),
            content: const Text(
              'Are you sure you want to delete this measurement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (canDelete == true) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false, // Prevent dismissing
              builder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final List<ClientMeasurement> measurements =
              List.from(client.measurements);

          final index = measurements.indexWhere(
            (m) =>
                m.bodyPart.toLowerCase() ==
                measurement.bodyPart.toLowerCase(),
          );
          measurements.removeAt(index);

          final updatedClient = client.copyWith(measurements: measurements);

          context
              .read<ClientBloc>()
              .add(UpdateClient(updatedClient));

          _deleteMeasurement(updatedClient);
        }
      },
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value:
                  context.read<ClientBloc>(), // reuse existing cubit
              child: AddClientMeasurementScreen(
                clientMeasurement: measurement,
                client: client,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteMeasurement(Client client) async {
    try {
      //_buttonLoadingStateCubit.setLoading(true);

      final result = await sl<FirebaseClientsService>().updateClientMeasurement(
        client,
      );

      result.fold(
        (l) {
          //_buttonLoadingStateCubit.setLoading(false);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
        },
      );
    } on FirebaseException catch (e) {
      //_buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  double cmToInches(double cm) {
    return cm / 2.54; // since 1 inch = 2.54 cm
  }

  double inchesToCm(double inches) {
    return inches * 2.54;
  }
}
