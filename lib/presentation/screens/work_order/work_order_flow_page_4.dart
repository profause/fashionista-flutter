import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class WorkOrderFlowPage4 extends StatefulWidget {
  final Function(WorkOrderModel workorder)? onNext;
  final VoidCallback? onPrev;
  const WorkOrderFlowPage4({super.key, this.onNext, this.onPrev});

  @override
  State<WorkOrderFlowPage4> createState() => _WorkOrderFlowPage4State();
}

class _WorkOrderFlowPage4State extends State<WorkOrderFlowPage4> {
  late WorkOrderModel current;
  List<String> previewImages = [];

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
          buildWhen: (context, state) {
            return state is WorkOrderPatched;
          },
          builder: (context, state) {
            // ✅ pre-fill values when coming back
            if (state is WorkOrderPatched) current = state.workorder;
            if (current.featuredMedia!.isNotEmpty) {
              previewImages = current.featuredMedia!
                  .map((p) => (p.url!))
                  .toList();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final image = previewImages[index];
                        return Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: image.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: image,
                                        fit: BoxFit.cover,
                                        height: 180,
                                        width: 180,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                            ),
                                      )
                                    : Image.file(
                                        File(image),
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
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(current.client!.name ?? ""),
                    subtitle: Text(current.client!.mobileNumber ?? ""),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(current.title),
                      ),
                      const Divider(height: .1, thickness: .1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(current.description ?? ""),
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
                        color: Colors.grey.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(current.startDate!),
                        ),
                      ),
                      const Divider(height: .1, thickness: .1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(current.dueDate!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (current.tags!.trim().isNotEmpty) ...[
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        current.tags!.split(',').length,
                        (index) => Chip(
                          label: Text(current.tags!.split(',')[index]),
                          padding: EdgeInsets.zero, // remove extra padding
                          visualDensity: VisualDensity.compact, // tighter look
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                        context.read<WorkOrderBloc>().add(
                          PatchWorkOrder(current),
                        );
                        widget.onNext!(current);
                      },
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
