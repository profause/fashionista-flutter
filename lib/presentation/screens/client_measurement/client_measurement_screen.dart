import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/client_measurement/add_client_measurement_screen.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<ClientCubit, ClientState>(
      builder: (context, state) {
        if (state is ClientDeleted) {
          if (mounted) {
            Navigator.pop(context);
          }
        }
        if (state is ClientLoaded || state is ClientUpdated) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: ListView.builder(
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
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: context.read<ClientCubit>(), // reuse existing cubit
                                            child: AddClientMeasurementScreen(
                                              clientMeasurement: measurement,
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
                                    color: AppTheme.lightGrey, // divider color
                                  ),
                                  IconButton(
                                    padding: const EdgeInsets.all(0),
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () {
                                      //_deleteMeasurement(measurement);
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
                            Text(
                              measurement.notes ?? '',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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
}
