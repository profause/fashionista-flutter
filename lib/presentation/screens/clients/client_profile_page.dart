import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:flutter/material.dart';
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
            margin: const EdgeInsets.all(4),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.client.fullName,
                        style: textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: .1, thickness: .1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.client.mobileNumber,
                        style: textTheme.titleMedium!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: .1, thickness: .1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(widget.client.gender, style: textTheme.titleMedium!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: .1, thickness: .1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(widget.client.createdDate!),
                        style: textTheme.titleSmall!,
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
}
