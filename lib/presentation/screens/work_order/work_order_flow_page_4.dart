import 'dart:io';

import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class WorkOrderFlowPage4 extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const WorkOrderFlowPage4({super.key, this.onNext, this.onPrev});

  @override
  State<WorkOrderFlowPage4> createState() => _WorkOrderFlowPage4State();
}

class _WorkOrderFlowPage4State extends State<WorkOrderFlowPage4> {
  late WorkOrderModel current;
  List<XFile> previewImages = [];

  @override
  void initState() {
    current = WorkOrderModel.empty();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
          builder: (context, state) {
            // ✅ pre-fill values when coming back
            if (state is WorkOrderUpdated) current = state.workorder;
            if (state is WorkOrderLoaded) current = state.workorder;
            if (current.featuredMedia!.isNotEmpty) {
              previewImages = current.featuredMedia!
                  .map((p) => XFile(p.url!))
                  .toList();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Review and save your work order',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (previewImages.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: previewImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final image = previewImages[index];
                        return Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(image.path),
                                  //width: 180,
                                  //height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    previewImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
                          Text('Save'),
                          SizedBox(width: 8),
                          Icon(Icons.check),
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
    );
  }
}
