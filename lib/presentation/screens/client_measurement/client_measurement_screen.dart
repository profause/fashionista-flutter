import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase_clients_service.dart';
import 'package:fashionista/presentation/screens/client_measurement/add_client_measurement_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    String _searchText = "";
    return BlocBuilder<ClientCubit, ClientState>(
      builder: (context, state) {
        if (state is ClientDeleted) {
          if (mounted) {
            Navigator.pop(context);
          }
        }
        if (state is ClientLoaded || state is ClientUpdated) {
          // final measurements = state.client.measurements
          //     .where(
          //       (m) => m.bodyPart.toLowerCase().contains(
          //         _searchText.toLowerCase(),
          //       ),
          //     )
          //     .toList();
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                SizeTransition(
                                  sizeFactor: animation,
                                  child: child,
                                ),
                            child: _isSearching
                                ? TextField(
                                    key: const ValueKey("searchField"),
                                    controller: _searchController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Search measurements...',
                                      border: InputBorder.none,
                                      hintStyle: textTheme.titleMedium,
                                    ),
                                    style: textTheme.bodyMedium,
                                    onChanged: (value) {
                                      setState(() => _searchText = value);
                                    },
                                  )
                                : Text(
                                    "",
                                    key: const ValueKey("title"),
                                    style: textTheme.titleLarge,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            _isSearching ? Icons.close : Icons.search,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 0),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.client.measurements.length,
                    itemBuilder: (context, index) {
                      final measurement = state.client.measurements[index];
                      return Card(
                        elevation: 0,
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    measurement.bodyPart, // e.g. "Chest"
                                    style: textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme
                                            .lightGrey, // or your preferred border color
                                        width: .5,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ), // adjust radius as needed
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          padding: const EdgeInsets.all(0),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BlocProvider.value(
                                                  value: context
                                                      .read<
                                                        ClientCubit
                                                      >(), // reuse existing cubit
                                                  child:
                                                      AddClientMeasurementScreen(
                                                        clientMeasurement:
                                                            measurement,
                                                        client: state.client,
                                                      ),
                                                ),
                                              ),
                                            );
                                            // Navigator.push(
                                            //   context,
                                            //   MaterialPageRoute(
                                            //     builder: (context) =>
                                            //         AddClientMeasurementScreen(
                                            //           clientMeasurement: measurement,
                                            //           clientUid: state.client.uid,
                                            //         ),
                                            //   ),
                                            // );
                                          },
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          height: 16,
                                          width: 1,
                                          color: AppTheme
                                              .lightGrey, // divider color
                                        ),
                                        IconButton(
                                          padding: const EdgeInsets.all(0),
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final canDelete = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Delete Measurement',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this measurement?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red,
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
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              }

                                              final List<ClientMeasurement>
                                              measurements = List.from(
                                                state.client.measurements,
                                              );

                                              final index = measurements
                                                  .indexWhere(
                                                    (m) =>
                                                        m.bodyPart
                                                            .toLowerCase() ==
                                                        measurement.bodyPart
                                                            .toLowerCase(),
                                                  );
                                              measurements.removeAt(index);

                                              final updatedClient = state.client
                                                  .copyWith(
                                                    measurements: measurements,
                                                  );

                                              context
                                                  .read<ClientCubit>()
                                                  .updateClient(updatedClient);

                                              _deleteMeasurement(updatedClient);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                children: [
                                  Text(
                                    "${measurement.measuredValue} cm", // e.g. "42 in"
                                    style: textTheme.titleSmall,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    height: 16,
                                    width: 1,
                                    color: AppTheme.lightGrey, // divider color
                                  ),
                                  Text(
                                    "${measurement.measuredValue} inches", // e.g. "42 in"
                                    style: textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    // divider color
                                    child: Text(
                                      measurement.notes ?? '',
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    height: 0,
                                    width: 1,
                                    color: AppTheme.lightGrey, // divider color
                                  ),
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(
                                      measurement.updatedDate == null
                                          ? DateTime.now()
                                          : measurement.updatedDate!,
                                    ),
                                    style: textTheme.titleSmall!,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                              .read<ClientCubit>(), // reuse existing cubit
                          child: AddClientMeasurementScreen(
                            clientMeasurement: ClientMeasurement.empty(),
                            client: state.client,
                          ),
                        ),
                      ),
                    );
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => AddClientMeasurementScreen(
                    //       clientMeasurement: ClientMeasurement.empty(),
                    //       clientUid: state.client.uid,
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
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }
}
