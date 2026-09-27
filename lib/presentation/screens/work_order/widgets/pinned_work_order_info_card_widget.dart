import 'dart:async';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PinnedWorkOrderInfoCardWidget extends StatefulWidget {
  final WorkOrderModel workOrderInfo;

  const PinnedWorkOrderInfoCardWidget({super.key, required this.workOrderInfo});

  @override
  State<PinnedWorkOrderInfoCardWidget> createState() =>
      _PinnedWorkOrderInfoCardWidgetState();
}

class _PinnedWorkOrderInfoCardWidgetState
    extends State<PinnedWorkOrderInfoCardWidget>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<bool>? isBookmarkedNotifier;
  late AnimationController _controller;
  Timer? _debounce; // 👈 debounce timer
  late ThemeMode themeMode;
  late SettingsBloc _settingsBloc;

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
    _settingsBloc = context.read<SettingsBloc>();
    themeMode = ThemeMode.values[_settingsBloc.state.displayMode as int];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final description = widget.workOrderInfo.description ?? '';
    final displayedDescription = description.length > 20
        ? '${description.substring(0, 17)}...'
        : description;
    final clientName = widget.workOrderInfo.client!.name ?? '';

    final displayedClientName = clientName.length > 20
        ? '${clientName.substring(0, 15)}...'
        : clientName;
    //final featuredMedia = workOrderInfo.featuredMedia!.first;
    return SizedBox(
      width: 285,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (widget.workOrderInfo.status == 'REQUEST') {
                context.push('/workorders/request/${widget.workOrderInfo.uid}');
              } else {
                context.push('/workorders/details/${widget.workOrderInfo.uid}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
                top: 4,
                bottom: 8,
              ),
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
                      const Spacer(),
                      ValueListenableBuilder<bool>(
                        valueListenable: isBookmarkedNotifier!,
                        builder: (_, isBookmarked, _) {
                          return CustomIconButtonRounded(
                            backgroundColor: Colors.grey.shade200.withValues(
                              alpha: 0,
                            ),
                            onPressed: () async {
                              isBookmarkedNotifier!.value = !isBookmarked;
                              _pinOrUnpinWorkOrder();
                            }, // safe to leave as empty
                            iconData: Icons.bookmark_border,
                            size: 16,
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
                                    ? colorScheme.primary
                                    : colorScheme.onPrimary,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    displayedDescription,
                    style: textTheme.bodyMedium,
                    maxLines: 2, // 👈 show only 2 lines (adjust as needed)
                    overflow: TextOverflow.ellipsis, // 👈 adds "..."
                  ),

                  //const SizedBox(height: 8),
                  const Spacer(),
                  Row(
                    children: [
                      Row(
                        children: [
                          CustomIconRounded(icon: Icons.person, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            displayedClientName,
                            maxLines: 1,
                            style: textTheme.labelMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.workOrderInfo.dueDate == null
                            ? 'no due date'
                            : DateFormat(
                                'yyyy-MM-dd',
                              ).format(widget.workOrderInfo.dueDate!),
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
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
        if (mounted) {
          context.read<WorkOrderBloc>().add(UpdateWorkOrder(updateWorkOrder));
        }
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
