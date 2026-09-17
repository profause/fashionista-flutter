import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
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

  final FocusNode _clientSearchFocusNode = FocusNode();
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
  void dispose() {
    _startDateTextFieldController.dispose();
    _dueDateTextFieldController.dispose();
    _clientSearchTextFieldController.dispose();
    _clientSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
                buildWhen: (context, state) {
                  return state is WorkOrderPatched;
                },
                builder: (context, state) {
                  // ✅ pre-fill values when coming back
                  if (state is WorkOrderPatched) current = state.workorder;
                  _selectedClientNotifier.value = current.client;
                  if (current.client != null) {
                    _clientListValueNotifier.value = [current.client!];
                  }

                  _clientSearchTextFieldController.text =
                      current.client?.name ?? "";
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign client & timeline',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: context.onCanvasText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select the client for this work order and choose your project completion timeline.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: context.mutedText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildClientCard(),
                      const SizedBox(height: 16),
                      _buildTimelineCard(),
                    ],
                  );
                },
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      color: context.hairline,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.5,
        child: Container(color: context.accent),
      ),
    );
  }

  Widget _buildClientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildClientSearchField(),
          const SizedBox(height: 16),
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
              const itemHeight = 60.0;
              final filteredClients = _searchText.isEmpty
                  ? clients
                  : clients.where((client) {
                      final name = client.name!.toLowerCase();
                      final mobileNumber = client.mobileNumber!.toLowerCase();
                      return name.contains(
                            _searchText.toLowerCase(),
                          ) ||
                          mobileNumber.contains(
                            _searchText.toLowerCase(),
                          );
                    }).toList();

              return SizedBox(
                height: (filteredClients.length * itemHeight).clamp(0, 300),
                child: ValueListenableBuilder<AuthorModel?>(
                  key: ValueKey(_selectedClientNotifier.value),
                  valueListenable: _selectedClientNotifier,
                  builder: (context, selectedClient, _) {
                    return ListView.builder(
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        final isSelected =
                            selectedClient?.mobileNumber ==
                            client.mobileNumber;

                        return _buildClientRow(client, isSelected);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClientSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 12, right: 12),
      decoration: BoxDecoration(
        color: context.iconSubstrate,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _clientSearchFocusNode.hasFocus
              ? context.accent
              : context.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: context.placeholderText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              autofocus: true,
              focusNode: _clientSearchFocusNode,
              controller: _clientSearchTextFieldController,
              onChanged: (value) => setState(() => _searchText = value),
              style: TextStyle(fontSize: 14, color: context.onCanvasText),
              decoration: InputDecoration(
                hintText: "Search client's name...",
                fillColor: Colors.transparent,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: context.placeholderText,
                  
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRow(AuthorModel client, bool isSelected) {
    return GestureDetector(
      onTap: () {
        _selectedClientNotifier.value = isSelected ? null : client;
      },
      child: Container(
        key: ValueKey(client.uid),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? context.accent.withValues(alpha: 0.06)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? context.accent : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? context.accent : context.iconSubstrate,
              ),
              child: Text(
                _getInitials(client.name),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : context.mutedText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name ?? "",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: context.onCanvasText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    client.mobileNumber ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      color: context.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            _buildRadio(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? context.accent : context.hairline,
          width: 1.8,
        ),
      ),
      child: isSelected
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.accent,
              ),
            )
          : null,
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "";
    final parts = name.split(" ").where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "";
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) +
            parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _buildTimelineCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDateRow(
            label: 'Start date',
            controller: _startDateTextFieldController,
            firstDate: current.startDate ?? DateTime.now(),
            initialDate: current.startDate ?? DateTime.now(),
          ),
          Divider(height: 1, thickness: 1, color: context.iconSubstrate),
          _buildDateRow(
            label: 'Due date',
            controller: _dueDateTextFieldController,
            firstDate: DateTime.now().add(const Duration(days: 7)),
            initialDate:
                current.dueDate ??
                DateTime.now().add(const Duration(days: 7)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required TextEditingController controller,
    required DateTime firstDate,
    required DateTime initialDate,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: DateTime(9000),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
          setState(() {});
        }
      },
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(controller.text),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.onCanvasText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.calendar_today,
                size: 20,
                color: context.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: context.canvasBackground.withValues(alpha: 0.95),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 54,
            child: OutlinedButton(
              onPressed: widget.onPrev,
              style: OutlinedButton.styleFrom(
                backgroundColor: context.cardSurface,
                foregroundColor: context.onCanvasText,
                side: BorderSide(color: context.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedPrimaryButton(
              text: 'Next',
              trailingIcon: Icons.arrow_forward,
              onPressed: () async {
                final startDate = DateTime.parse(
                  _startDateTextFieldController.text,
                );
                final dueDate = DateTime.parse(
                  _dueDateTextFieldController.text,
                );

                if (startDate.isAfter(dueDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Start date cannot be after due date',
                      ),
                    ),
                  );
                  return;
                }

                if (startDate == dueDate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Start date cannot be same as due date',
                      ),
                    ),
                  );
                  return;
                }

                final selected = _selectedClientNotifier.value;
                if (selected == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a client to continue'),
                    ),
                  );
                  return;
                }

                final client = AuthorModel.empty().copyWith(
                  uid: selected.uid,
                  name: selected.name,
                  mobileNumber: selected.mobileNumber,
                );

                final workOrder = current.copyWith(
                  startDate: startDate,
                  dueDate: dueDate,
                  client: client,
                );
                context.read<WorkOrderBloc>().add(
                  PatchWorkOrder(workOrder),
                );
                widget.onNext!();
              },
            ),
          ),
        ],
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