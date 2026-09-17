import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WorkOrderInfoCardWidget extends StatefulWidget {
  final WorkOrderModel workOrderInfo;

  const WorkOrderInfoCardWidget({super.key, required this.workOrderInfo});

  @override
  State<WorkOrderInfoCardWidget> createState() =>
      _WorkOrderInfoCardWidgetState();
}

class _WorkOrderInfoCardWidgetState extends State<WorkOrderInfoCardWidget>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<bool>? isBookmarkedNotifier;
  late AnimationController _controller;
  Timer? _debounce; // 👈 debounce timer

  @override
  void initState() {
    isBookmarkedNotifier = ValueNotifier(widget.workOrderInfo.isBookmarked!);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    isBookmarkedNotifier!.addListener(() {
      if (isBookmarkedNotifier!.value) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final workOrder = widget.workOrderInfo;
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (workOrder.status == 'REQUEST') {
              context.push('/workorders/request/${workOrder.uid}');
            } else {
              context.push('/workorders/details/${workOrder.uid}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    //border: Border.all(color: context.hairline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: workOrder.featuredMedia!.isEmpty
                          ? ''
                          : workOrder.featuredMedia!.first.url!.trim(),
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                workOrder.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.onCanvasText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: isBookmarkedNotifier!,
                              builder: (_, isBookmarked, _) {
                                return GestureDetector(
                                  onTap: () {
                                    isBookmarkedNotifier!.value = !isBookmarked;
                                    _pinOrUnpinWorkOrder();
                                  },
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border_outlined,
                                      key: ValueKey(isBookmarked),
                                      color: isBookmarked
                                          ? context.accent
                                          : context.mutedText,
                                      size: 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                          workOrder.description ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.mutedText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.iconSubstrate,
                                //border: Border.all(color: context.hairline),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 10,
                                color: context.mutedText,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                workOrder.client?.name ?? "",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.mutedText,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.accent.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: context.accent.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Text(
                                workOrder.dueDate != null
                                    ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(workOrder.dueDate!)
                                    : 'no due date',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pinOrUnpinWorkOrder() {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await sl<FirebaseWorkOrderService>().pinOrUnpinWorkOrder(
        widget.workOrderInfo.uid!,
      );
      result.fold((l) {}, (r) {
        isBookmarkedNotifier!.value = r;
        final updateWorkOrder = widget.workOrderInfo.copyWith(isBookmarked: r);
        context.read<WorkOrderBloc>().add(UpdateWorkOrder(updateWorkOrder));
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
