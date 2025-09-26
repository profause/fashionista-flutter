import 'dart:async';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/project_details_screen.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PinnedWorkOrderInfoCardWidget extends StatefulWidget {
  final WorkOrderModel workOrderInfo;
  final VoidCallback? onTap;

  const PinnedWorkOrderInfoCardWidget({
    super.key,
    required this.workOrderInfo,
    this.onTap,
  });

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
    //final featuredMedia = workOrderInfo.featuredMedia!.first;
    return SizedBox(
      width: 250,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
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
              padding: const EdgeInsets.all(10),
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
                        builder: (_, isBookmarked, __) {
                          return CustomIconButtonRounded(
                            backgroundColor: Colors.grey.shade200,
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

                  const SizedBox(height: 12),
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
