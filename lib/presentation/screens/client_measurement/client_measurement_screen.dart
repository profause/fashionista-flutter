import 'package:fashionista/core/service_locator/service_locator.dart';
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
  //bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
     //context.read<ClientBloc>().add(UpdateClient(widget.client));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    //String _searchText = "";
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
            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card(
                  //   color: colorScheme.onPrimary,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(0),
                  //   ),
                  //   elevation: 0,
                  //   margin: const EdgeInsets.symmetric(vertical: 2),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(8),
                  //     child: Row(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Expanded(
                  //           child: TextField(
                  //             key: const ValueKey("searchField"),
                  //             controller: _searchController,
                  //             autofocus: true,
                  //             decoration: InputDecoration(
                  //               hintText: 'Search measurements...',
                  //               border: InputBorder.none,
                  //               hintStyle: textTheme.labelMedium,
                  //             ),
                  //             style: textTheme.bodyLarge,
                  //             onChanged: (value) {
                  //               setState(() {
                  //                 _isSearching = value.isNotEmpty;
                  //                 _searchText = value;
                  //               });
                  //             },
                  //           ),
                  //         ),
                  //         const SizedBox(width: 12),
                  //         Padding(
                  //           padding: const EdgeInsets.only(right: 12),
                  //           child: CustomIconButtonRounded(
                  //             iconData: _isSearching
                  //                 ? Icons.close
                  //                 : Icons.search,
                  //             onPressed: () {
                  //               setState(() {
                  //                 _isSearching = !_isSearching;
                  //                 if (!_isSearching) {
                  //                   _searchController.clear();
                  //                 }
                  //               });
                  //             },
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 0),
                  
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: client.measurements.length,
                      itemBuilder: (context, index) {
                        final measurement = client.measurements[index];
                        return MeasurementInfoCardWidget(
                          client: widget.client,
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

                              final List<ClientMeasurement> measurements =
                                  List.from(client.measurements);

                              final index = measurements.indexWhere(
                                (m) =>
                                    m.bodyPart.toLowerCase() ==
                                    measurement.bodyPart.toLowerCase(),
                              );
                              measurements.removeAt(index);

                              final updatedClient = client.copyWith(
                                measurements: measurements,
                              );

                              context.read<ClientBloc>().add(
                                UpdateClient(updatedClient),
                              );

                              _deleteMeasurement(updatedClient);
                            }
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context
                                      .read<
                                        ClientBloc
                                      >(), // reuse existing cubit
                                  child: AddClientMeasurementScreen(
                                    clientMeasurement: measurement,
                                    client: client,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              floatingActionButton: Hero(
                tag: 'add-measurement-button',
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context
                                .read<ClientBloc>(), // reuse existing cubit
                            child: AddClientMeasurementScreen(
                              clientMeasurement: ClientMeasurement.empty(),
                              client: client,
                            ),
                          ),
                        ),
                      );
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => AddClientMeasurementScreen(
                      //       clientMeasurement: ClientMeasurement.empty(),
                      //       clientUid: client.uid,
                      //     ),
                      //   ),
                      // );
                    },
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.add, color: colorScheme.onPrimary),
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
