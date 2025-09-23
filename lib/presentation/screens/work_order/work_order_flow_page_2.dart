import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/presentation/screens/profile/widgets/date_picker_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkOrderFlowPage2 extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  const WorkOrderFlowPage2({super.key, this.onNext, this.onPrev});

  @override
  State<WorkOrderFlowPage2> createState() => _WorkOrderFlowPage2State();
}

class _WorkOrderFlowPage2State extends State<WorkOrderFlowPage2> {
  late TextEditingController _startDateTextFieldController;
  late TextEditingController _dueDateTextFieldController;
  late TextEditingController _clientSearchTextFieldController;

  String _searchText = "";
  late ValueNotifier<List<Client>> _clientListValueNotifier;
  late ValueNotifier<Client?> _selectedClientNotifier; // ✅ selection state

  @override
  void initState() {
    super.initState();
    _startDateTextFieldController = TextEditingController();
    _dueDateTextFieldController = TextEditingController();
    _clientSearchTextFieldController = TextEditingController();

    _clientListValueNotifier = ValueNotifier<List<Client>>([]);
    _selectedClientNotifier = ValueNotifier<Client?>(null);

    fetchCachedClients();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Client Search & List
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomTextInputFieldWidget(
                        autofocus: true,
                        controller: _clientSearchTextFieldController,
                        hint: 'Client name',
                        validator: (value) {
                          if ((value ?? "").isEmpty) {
                            return 'enter your client name...';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() => _searchText = value);
                        },
                      ),
                    ),
                    const Divider(height: .1, thickness: .1),

                    // Listen for clients
                    ValueListenableBuilder<List<Client>>(
                      valueListenable: _clientListValueNotifier,
                      builder: (context, clients, _) {
                        if (clients.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("No clients available"),
                            ),
                          );
                        }

                        const itemHeight = 70.0;
                        final filteredClients = _searchText.isEmpty
                            ? clients
                            : clients.where((client) {
                                final name = client.fullName.toLowerCase();
                                final mobileNumber = client.mobileNumber
                                    .toLowerCase();
                                return name.contains(
                                      _searchText.toLowerCase(),
                                    ) ||
                                    mobileNumber.contains(
                                      _searchText.toLowerCase(),
                                    );
                              }).toList();

                        return SizedBox(
                          height: (filteredClients.length * itemHeight).clamp(
                            0,
                            300,
                          ),
                          child: ValueListenableBuilder<Client?>(
                            valueListenable: _selectedClientNotifier,
                            builder: (context, selectedClient, __) {
                              return ListView.builder(
                                itemCount: filteredClients.length,
                                itemBuilder: (context, index) {
                                  final client = filteredClients[index];
                                  final isSelected =
                                      selectedClient?.uid == client.uid;

                                  return Container(
                                    color: isSelected
                                        ? colorScheme.surface.withValues(
                                            alpha: 1,
                                          )
                                        : null,
                                    child: ListTile(
                                      leading: const Icon(Icons.person),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle,
                                              size: 18,
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.7),
                                            )
                                          : null,
                                      title: Text(client.fullName),
                                      subtitle: Text(client.mobileNumber),
                                      onTap: () {
                                        _selectedClientNotifier.value =
                                            isSelected ? null : client;
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date Pickers
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DatePickerFormField(
                        label: 'Start date',
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(9000),
                        controller: _startDateTextFieldController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select a date'
                            : null,
                        onChanged: (date) {
                          if (date != null) {
                            final formattedDate = DateFormat(
                              'yyyy-MM-dd',
                            ).format(date);
                            _startDateTextFieldController.text = formattedDate;
                          }
                        },
                      ),
                    ),
                    const Divider(height: .1, thickness: .1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DatePickerFormField(
                        label: 'Due date',
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now().add(const Duration(days: 7)),
                        lastDate: DateTime(9000),
                        controller: _dueDateTextFieldController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select a date'
                            : null,
                        onChanged: (date) {
                          if (date != null) {
                            final formattedDate = DateFormat(
                              'yyyy-MM-dd',
                            ).format(date);
                            _dueDateTextFieldController.text = formattedDate;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: widget.onPrev,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back),
                        SizedBox(width: 8),
                        Text('Previous'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: widget.onNext,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Next'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchCachedClients() async {
    String uid = "";
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = us.uid;
    }
    final cachedItems = await sl<HiveClientService>().getItems(uid);
    if (cachedItems.isNotEmpty) {
      _clientListValueNotifier.value = cachedItems;
    }
  }
}
