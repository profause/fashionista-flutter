import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
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
    //context.read<ClientBloc>().add(LoadClient(widget.client.uid));
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
            return Scaffold(
              backgroundColor: context.canvasBackground,
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        _ProfileDetailRow(
                          icon: Icons.person,
                          label: 'Full Name',
                          value: client.fullName,
                        ),
                        const _RowDivider(),
                        _ProfileDetailRow(
                          icon: Icons.phone,
                          label: 'Mobile Number',
                          value: client.mobileNumber,
                        ),
                        const _RowDivider(),
                        _ProfileDetailRow(
                          icon: _genderIcon(client.gender),
                          label: 'Gender',
                          value: client.gender,
                        ),
                        const _RowDivider(),
                        _ProfileDetailRow(
                          icon: Icons.calendar_month,
                          label: 'Registration Date',
                          value: DateFormat(
                            'MMM dd, yyyy',
                          ).format(client.createdDate!),
                        ),
                      ],
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

IconData _genderIcon(String? gender) {
  return gender == 'Male' ? Icons.man : Icons.woman;
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.hairline);
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: context.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.mutedText,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.onCanvasText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
