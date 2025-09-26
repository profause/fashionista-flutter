import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/project_details_screen.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkOrderInfoCardWidget extends StatefulWidget {
  final WorkOrderModel workOrderInfo;
  final VoidCallback? onTap; // Callback for navigation or action

  const WorkOrderInfoCardWidget({
    super.key,
    required this.workOrderInfo,
    this.onTap,
  });

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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    //final featuredMedia = workOrderInfo.featuredMedia!.first;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProjectDetailsScreen(workOrderInfo: widget.workOrderInfo),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: widget.workOrderInfo.featuredMedia!.isEmpty
                            ? ''
                            : widget.workOrderInfo.featuredMedia!.first.url!
                                  .trim(),
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.workOrderInfo.title,
                              style: textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: isBookmarkedNotifier!,
                            builder: (_, isBookmarked, __) {
                              return CustomIconButtonRounded(
                                onPressed: () async {
                                  isBookmarkedNotifier!.value = !isBookmarked;
                                  _pinOrUnpinWorkOrder();
                                }, // safe to leave as empty
                                iconData: Icons.bookmark_border,
                                size: 18,
                                icon: AnimatedSwitcher(
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
                                    key: ValueKey(
                                      isBookmarked,
                                    ), // important for switcher
                                    color: isBookmarked
                                        ? Colors.black
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        widget.workOrderInfo.description ?? '',
                        style: textTheme.bodyMedium,
                        maxLines: 2, // 👈 show only 2 lines (adjust as needed)
                        overflow: TextOverflow.ellipsis, // 👈 adds "..."
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: [
                              CustomIconRounded(icon: Icons.person, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                widget.workOrderInfo.client!.name!,
                                style: textTheme.labelMedium,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            DateFormat(
                              'yyyy-MM-dd',
                            ).format(widget.workOrderInfo.dueDate!),
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
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
        widget.onTap!();
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
