import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
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
                  if (current.featuredMedia!.isNotEmpty &&
                      previewImages.isEmpty) {
                    previewImages = current.featuredMedia!
                        .map((p) => (p.url!))
                        .toList();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review & confirm',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: context.onCanvasText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Double-check your work order details and photos before creating the order.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: context.mutedText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPhotoSection(),
                      const SizedBox(height: 20),
                      _buildSummaryCard(),
                      if (current.tags!.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildTagsSection(),
                      ],
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
        widthFactor: 1,
        child: Container(color: context.accent),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (previewImages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'UPLOADED PHOTOS (${previewImages.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: context.mutedText,
              ),
            ),
            const Spacer(),
            Text(
              'Step 4 of 4',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewImages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final image = previewImages[index];
              return _buildPhotoCard(image, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(String image, int index) {
    return Stack(
      children: [
        Container(
          width: 130,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: context.hairline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                  )
                : Image.file(File(image), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                previewImages.removeAt(index);
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REVIEW PROJECT SUMMARY',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: context.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
              _buildSummaryRow(
                label: 'PROJECT TITLE',
                value: current.title,
              ),
              Divider(height: 1, thickness: 1, color: context.hairline),
              _buildClientRow(),
              Divider(height: 1, thickness: 1, color: context.hairline),
              _buildTimelineRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.onCanvasText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRow() {
    final clientName = current.client?.name ?? "";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLIENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clientName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.onCanvasText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            current.client?.mobileNumber ?? "",
            style: TextStyle(
              fontSize: 12,
              color: context.mutedText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.accent,
            ),
            child: Text(
              _getInitials(clientName),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow() {
    final startDate = DateFormat('MMM dd, yyyy').format(current.startDate!);
    final dueDate = DateFormat('MMM dd, yyyy').format(current.dueDate!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIMELINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$startDate – $dueDate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.onCanvasText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.accent.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 18,
              color: context.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    final tags = current.tags!
        .split(',')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'STYLE INSPIRATION TAGS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: context.mutedText,
                ),
              ),
              const Spacer(),
              Text(
                '${tags.length} tags attached',
                style: TextStyle(
                  fontSize: 12,
                  color: context.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: context.iconSubstrate,
                      borderRadius: BorderRadius.circular(16),
                      //border: Border.all(color: context.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.onCanvasText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          size: 14,
                          color: context.mutedText,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: context.canvasBackground.withValues(alpha: 0.95),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
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
              text: 'Create Work Order',
              trailingIcon: Icons.check,
              onPressed: () async {
                context.read<WorkOrderBloc>().add(
                  PatchWorkOrder(current),
                );
                widget.onNext!(current);
              },
            ),
          ),
        ],
      ),
    );
  }
}