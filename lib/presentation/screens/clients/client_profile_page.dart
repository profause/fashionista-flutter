import 'package:fashionista/data/models/clients/bloc/client_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ClientProfilePage extends StatefulWidget {
  final Client client;
  const ClientProfilePage({super.key, required this.client});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
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
            body: Column(
              children: [
                Card(
                  elevation: 0,
                  color: colorScheme.onPrimary, // subtle background tint
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person),
                            const SizedBox(width: 8),
                            Text(
                              state.client.fullName,
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: .1, thickness: .1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.phone),
                            const SizedBox(width: 8),
                            Text(
                              state.client.mobileNumber,
                              style: textTheme.labelMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: .1, thickness: .1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              state.client.gender == 'Male'
                                  ? Icons.man
                                  : Icons.woman,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.client.gender,
                              style: textTheme.labelMedium!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: .1, thickness: .1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_month),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'yyyy-MM-dd',
                              ).format(state.client.createdDate!),
                              style: textTheme.labelMedium!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
