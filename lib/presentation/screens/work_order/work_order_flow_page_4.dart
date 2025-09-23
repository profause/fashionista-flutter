import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';

class WorkOrderFlowPage4 extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const WorkOrderFlowPage4({super.key, this.onNext, this.onPrev});

  @override
  State<WorkOrderFlowPage4> createState() => _WorkOrderFlowPage4State();
}

class _WorkOrderFlowPage4State extends State<WorkOrderFlowPage4> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
                      Text('Save'),
                      SizedBox(width: 8),
                      Icon(Icons.check),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
