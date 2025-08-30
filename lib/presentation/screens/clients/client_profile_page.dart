import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
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
        //debugPrint('_ClientProfilePageState: ' + state.toString());
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
                                client.fullName,
                                style: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: .1, thickness: .1, indent: 32),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.phone),
                              const SizedBox(width: 8),
                              Text(
                                client.mobileNumber,
                                style: textTheme.labelMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: .1, thickness: .1, indent: 32),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                client.gender == 'Male'
                                    ? Icons.man
                                    : Icons.woman,
                                size: 26,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                client.gender,
                                style: textTheme.labelMedium!,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: .1, thickness: .1, indent: 32),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_month),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'yyyy-MM-dd',
                                ).format(client.createdDate!),
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
          case ClientError(:final message):
            return Center(child: Text(message));
          default:
            return const Center(child: Text('Unknown state'));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
