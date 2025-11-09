import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkOrderFlowPage1 extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final WorkOrderModel? workOrder;
  const WorkOrderFlowPage1({
    super.key,
    this.onNext,
    this.onPrev,
    this.workOrder,
  });

  @override
  State<WorkOrderFlowPage1> createState() => _WorkOrderFlowPage1State();
}

class _WorkOrderFlowPage1State extends State<WorkOrderFlowPage1> {
  late TextEditingController _titleTextFieldController;
  late TextEditingController _descriptionTextFieldController;
  late WorkOrderModel current = WorkOrderModel.empty();
  @override
  void initState() {
    if (widget.workOrder != null) {
      current = WorkOrderModel.empty();
      context.read<WorkOrderBloc>().add(PatchWorkOrder(widget.workOrder!));
    }
    _titleTextFieldController = TextEditingController();
    _descriptionTextFieldController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        // ensures it's still scrollable on small screens
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
          buildWhen: (context, state) {
            return state is WorkOrderPatched;
          },
          builder: (context, state) {
            if (state is WorkOrderPatched) {
              current = state.workorder;
              _titleTextFieldController.text = current.title;
              _descriptionTextFieldController.text = current.description ?? "";
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.start, // centers vertically
              children: [
                Text(
                  "Start by providing a title and description for your work order.",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 128),
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
                          controller: _titleTextFieldController,
                          hint: 'Title...',
                          validator: (value) {
                            if ((value ?? "").isEmpty) {
                              return 'Enter title to get started...';
                            }
                            return null;
                          },
                        ),
                      ),
                      const Divider(height: .1, thickness: .1),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextInputFieldWidget(
                          autofocus: false,
                          controller: _descriptionTextFieldController,
                          hint: 'Describe style inspiration...',
                          minLines: 2,
                          maxLength: 150,
                          validator: (value) {
                            if ((value ?? "").isEmpty) {
                              return 'Enter description to get proceed...';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: OutlinedButton(
                    onPressed: () {
                      if (_titleTextFieldController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter title to get started...'),
                          ),
                        );
                        return;
                      }

                      if (_descriptionTextFieldController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter description to proceed...'),
                          ),
                        );
                        return;
                      }

                      final workOrder = current.copyWith(
                        title: _titleTextFieldController.text.trim(),
                        description: _descriptionTextFieldController.text
                            .trim(),
                      );
                      context.read<WorkOrderBloc>().add(
                        PatchWorkOrder(workOrder),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
