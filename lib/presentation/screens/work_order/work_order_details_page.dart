import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkOrderDetailsPage extends StatefulWidget {
  final WorkOrderModel workOrderInfo;
  const WorkOrderDetailsPage({super.key, required this.workOrderInfo});

  @override
  State<WorkOrderDetailsPage> createState() => _WorkOrderDetailsPageState();
}

class _WorkOrderDetailsPageState extends State<WorkOrderDetailsPage> {
  static const List<String> _stages = [
    'Measurements Confirmed',
    'Fabric Preparation & Cutting',
    'First Client Fitting',
    'Final Handover & Delivery',
  ];

  @override
  Widget build(BuildContext context) {
    final workOrder = widget.workOrderInfo;
    final tags = (workOrder.tags ?? '')
        .split(',')
        .where((t) => t.trim().isNotEmpty)
        .toList();

    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workOrder.featuredMedia!.isNotEmpty) ...[
                  _buildReferenceHeader(context),
                  const SizedBox(height: 10),
                  _buildCarousel(context),
                  const SizedBox(height: 16),
                ],
                _buildDetailsCard(context),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTagsCard(context, tags),
                ],
                const SizedBox(height: 16),
                _buildProgressCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Reference Imagery ───────────────────────────────────────────────
  Widget _buildReferenceHeader(BuildContext context) {
    final workOrder = widget.workOrderInfo;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'REFERENCE IMAGERY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.mutedText,
            ),
          ),
          Text(
            '${workOrder.featuredMedia!.length} Photos',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    final workOrder = widget.workOrderInfo;
    return SizedBox(
      height: 208,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: workOrder.featuredMedia!.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final image = workOrder.featuredMedia![index].url;
          return Container(
            width: 176,
            height: 208,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(12),
              //border: Border.all(color: context.hairline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: image!.isEmpty ? '' : image.trim(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      const CustomColoredBanner(text: ''),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Look ${(index + 1).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Consolidated Project Details ───────────────────────────────────
  Widget _buildDetailsCard(BuildContext context) {
    final workOrder = widget.workOrderInfo;
    final client = workOrder.client;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (client != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.accent,
                    child: Text(
                      _initials(client.name ?? ''),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.onCanvasText,
                          ),
                        ),
                        if ((client.mobileNumber ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            client.mobileNumber!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if ((client.mobileNumber ?? '').isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _callClient(client.mobileNumber!),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.canvasBackground,
                            borderRadius: BorderRadius.circular(999),
                            //border: Border.all(color: context.hairline),
                          ),
                          child: Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: context.onCanvasText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          _hairlineDivider(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROJECT TITLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workOrder.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.onCanvasText,
                  ),
                ),
                if ((workOrder.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.iconSubstrate,
                      borderRadius: BorderRadius.circular(12),
                      //border: Border.all(color: context.hairline),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Style Notes: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.onCanvasText,
                            ),
                          ),
                          TextSpan(
                            text: workOrder.description,
                            style: TextStyle(color: context.onCanvasText),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _hairlineDivider(context),
          _buildTimelineRow(context),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(BuildContext context) {
    final workOrder = widget.workOrderInfo;
    final start = workOrder.startDate;
    final due = workOrder.dueDate;
    final hasStart = start != null;
    final hasDue = due != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (hasStart) ...[
            Text(
              'Start:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.mutedText,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                DateFormat('MMM d, yyyy').format(start),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.onCanvasText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: context.mutedText.withValues(alpha: 0.7),
            ),
          ],
          const Spacer(),
          if (hasDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.accent.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: context.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${DateFormat('MMM d, yyyy').format(due)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.accent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Inspiration Moodboard Tags ─────────────────────────────────────
  Widget _buildTagsCard(BuildContext context, List<String> tags) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'INSPIRATION MOODBOARD TAGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.iconSubstrate,
                  borderRadius: BorderRadius.circular(999),
                  //border: Border.all(color: context.hairline),
                ),
                child: Text(
                  '#${tag.trim()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.onCanvasText,
                  ),
                ),
              ),
            );
          }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Production Progress ────────────────────────────────────────────
  Widget _buildProgressCard(BuildContext context) {
    final activeIndex = _activeStageIndex(widget.workOrderInfo.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Production Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.onCanvasText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: context.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _statusLabel(widget.workOrderInfo.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: context.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _stages.length; i++) ...[
            _buildStageRow(context, i, activeIndex),
            if (i < _stages.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(width: 2, height: 44, color: context.hairline),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageRow(BuildContext context, int index, int activeIndex) {
    final isCompleted = index < activeIndex;
    final isActive = index == activeIndex;
    final workOrder = widget.workOrderInfo;

    String? dateText;
    if (index == 0 && workOrder.startDate != null) {
      dateText = DateFormat('MMM d').format(workOrder.startDate!);
    } else if (index == _stages.length - 1 && workOrder.dueDate != null) {
      dateText = DateFormat('MMM d').format(workOrder.dueDate!);
    }

    final Color nodeBorder;
    final Widget nodeChild;
    if (isCompleted) {
      nodeBorder = const Color(0xFF22C55E);
      nodeChild = const Icon(Icons.check, size: 14, color: Color(0xFF22C55E));
    } else if (isActive) {
      nodeBorder = context.accent;
      nodeChild = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.accent,
        ),
      );
    } else {
      nodeBorder = const Color(0xFFD1D5DB);
      nodeChild = Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFD1D5DB),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.cardSurface,
            border: Border.all(color: nodeBorder, width: 2),
          ),
          child: Center(child: nodeChild),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      _stages[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : isCompleted
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: isActive
                            ? context.accent
                            : isCompleted
                            ? context.onCanvasText
                            : context.mutedText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isActive)
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: context.accent,
                      ),
                    )
                  else if (dateText != null)
                    Text(
                      dateText,
                      style: TextStyle(fontSize: 11, color: context.mutedText),
                    ),
                ],
              ),
              if (!isActive && index == 0)
                Text(
                  'Precise bespoke dimensions archived.',
                  style: TextStyle(fontSize: 12, color: context.mutedText),
                ),
              if (isActive)
                Text(
                  'Following the confirmed measurements.',
                  style: TextStyle(fontSize: 12, color: context.mutedText),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Widget _hairlineDivider(BuildContext context) {
    return Divider(color: context.hairline, height: 1, thickness: 1);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  int _activeStageIndex(String? status) {
    final s = (status ?? '').toUpperCase();
    if (s.contains('COMPLET') || s.contains('DONE')) return _stages.length;
    if (s.contains('MEASURE')) return 0;
    if (s.contains('FABRIC') ||
        s.contains('CUTT') ||
        s.contains('PREP') ||
        s.contains('PROGRESS')) {
      return 1;
    }
    if (s.contains('FITT')) return 2;
    if (s.contains('FINAL') ||
        s.contains('DELIVER') ||
        s.contains('HANDOVER')) {
      return 3;
    }
    return 1;
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'REQUEST':
        return 'Requested';
      case 'IN_PROGRESS':
      case 'PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
      case 'DONE':
        return 'Completed';
      case 'CANCELLED':
      case 'CANCELED':
        return 'Cancelled';
      case 'DRAFT':
      case 'NEW':
        return 'Draft';
      case '':
        return 'In Progress';
      default:
        return status!;
    }
  }

  Future<void> _callClient(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
