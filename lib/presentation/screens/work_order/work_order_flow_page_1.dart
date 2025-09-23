import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:flutter/material.dart';

class WorkOrderFlowPage1 extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  const WorkOrderFlowPage1({super.key, this.onNext, this.onPrev});

  @override
  State<WorkOrderFlowPage1> createState() => _WorkOrderFlowPage1State();
}

class _WorkOrderFlowPage1State extends State<WorkOrderFlowPage1> {
  late TextEditingController _titleTextFieldController;
  late TextEditingController _descriptionTextFieldController;
  @override
  void initState() {
    _titleTextFieldController = TextEditingController();
    _descriptionTextFieldController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          // ensures it's still scrollable on small screens
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // centers vertically
            children: [
              Text(
                "Start by providing a title and description for your work order.",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
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
                        hint: 'Description...',
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
                  onPressed: () => widget.onNext!(),
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
          ),
        ),
      ),
    );
  }
}
