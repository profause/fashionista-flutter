import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
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
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  int _descriptionLength = 0;

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
  void dispose() {
    _titleTextFieldController.dispose();
    _descriptionTextFieldController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
                buildWhen: (context, state) {
                  return state is WorkOrderPatched;
                },
                builder: (context, state) {
                  if (state is WorkOrderPatched) {
                    current = state.workorder;
                    _titleTextFieldController.text = current.title;
                    _descriptionTextFieldController.text =
                        current.description ?? "";
                    _descriptionLength =
                        _descriptionTextFieldController.text.length;
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Provide project details",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: context.onCanvasText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Start by giving your work order a title and describing your style inspiration.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: context.mutedText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTitleField(),
                      const SizedBox(height: 16),
                      _buildDescriptionField(),
                    ],
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: context.canvasBackground.withValues(alpha: 0.95),
            ),
            child: AnimatedPrimaryButton(
              text: "Next",
              trailingIcon: Icons.arrow_forward,
              onPressed: () async {
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
                  description:
                      _descriptionTextFieldController.text.trim(),
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

  Widget _buildTitleField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _titleFocusNode.hasFocus
              ? context.accent
              : context.hairline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        focusNode: _titleFocusNode,
        autofocus: true,
        controller: _titleTextFieldController,
        validator: (value) {
          if ((value ?? "").isEmpty) {
            return 'Enter title to get started...';
          }
          return null;
        },
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: context.onCanvasText,
        ),
        decoration: InputDecoration(
          hintText: 'Project Title (e.g., Kente Wedding Dress)...',
          hintStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.placeholderText,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _descriptionFocusNode.hasFocus
              ? context.accent
              : context.hairline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            focusNode: _descriptionFocusNode,
            controller: _descriptionTextFieldController,
            minLines: 4,
            maxLines: 5,
            maxLength: 150,
            validator: (value) {
              if ((value ?? "").isEmpty) {
                return 'Enter description to get proceed...';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _descriptionLength = value.length;
              });
            },
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: context.onCanvasText,
            ),
            decoration: InputDecoration(
              hintText:
                  'Describe style inspiration, fabric preference, or alteration needs...',
              hintStyle: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: context.placeholderText,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '$_descriptionLength/150',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
