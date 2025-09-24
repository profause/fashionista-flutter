import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/presentation/screens/profile/widgets/date_picker_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late WorkOrderModel current;

  String _searchText = "";
  late ValueNotifier<List<AuthorModel>> _clientListValueNotifier;
  late ValueNotifier<AuthorModel?> _selectedClientNotifier; // ✅ selection state

  @override
  void initState() {
    super.initState();
    current = WorkOrderModel.empty();
    _startDateTextFieldController = TextEditingController();
    _dueDateTextFieldController = TextEditingController();
    _clientSearchTextFieldController = TextEditingController();

    _clientListValueNotifier = ValueNotifier<List<AuthorModel>>([]);
    _selectedClientNotifier = ValueNotifier<AuthorModel?>(null);

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
          child: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
            builder: (context, state) {
              // ✅ pre-fill values when coming back
              if (state is WorkOrderUpdated) current = state.workorder;
              if (state is WorkOrderLoaded) current = state.workorder;
              _selectedClientNotifier.value = current.client;
              _startDateTextFieldController.text = DateFormat(
                'yyyy-MM-dd',
              ).format(current.startDate ?? DateTime.now());
              _dueDateTextFieldController.text = DateFormat('yyyy-MM-dd')
                  .format(
                    current.dueDate ??
                        DateTime.now().add(const Duration(days: 7)),
                  );
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Who is this work order for?. And when do you think it will be done?.',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 16),
                  // Client Search & List
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CustomTextInputFieldWidget(
                            autofocus: true,
                            controller: _clientSearchTextFieldController,
                            hint: 'Search client\'s name',
                            validator: (value) {
                              if ((value ?? "").isEmpty) {
                                return 'Enter your client name...';
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
                        ValueListenableBuilder<List<AuthorModel>>(
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
                                    final name = client.name!.toLowerCase();
                                    final mobileNumber = client.mobileNumber!
                                        .toLowerCase();
                                    return name.contains(
                                          _searchText.toLowerCase(),
                                        ) ||
                                        mobileNumber.contains(
                                          _searchText.toLowerCase(),
                                        );
                                  }).toList();

                            return SizedBox(
                              height: (filteredClients.length * itemHeight)
                                  .clamp(0, 300),
                              child: ValueListenableBuilder<AuthorModel?>(
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
                                          title: Text(client.name ?? ""),
                                          subtitle: Text(
                                            client.mobileNumber ?? "",
                                          ),
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
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
                                _startDateTextFieldController.text =
                                    formattedDate;
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
                            firstDate: DateTime.now().add(
                              const Duration(days: 7),
                            ),
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
                                _dueDateTextFieldController.text =
                                    formattedDate;
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
                        onPressed: () {
                          final workOrder = current.copyWith(
                            startDate: DateTime.parse(
                              _startDateTextFieldController.text,
                            ),
                            dueDate: DateTime.parse(
                              _dueDateTextFieldController.text,
                            ),
                            client: _selectedClientNotifier.value,
                          );
                          context.read<WorkOrderBloc>().add(
                            UpdateWorkOrder(workOrder),
                          );
                          widget.onNext!();
                        },
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
              );
            },
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
      _clientListValueNotifier.value = cachedItems
          .map(
            (client) => AuthorModel.empty().copyWith(
              name: client.fullName,
              uid: client.uid,
              mobileNumber: client.mobileNumber,
            ),
          )
          .toList();
    }
  }
}
