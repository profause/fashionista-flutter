import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_event.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/hive/hive_notification_service.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_info_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_work_order_request_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_work_order_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late UserBloc _userBloc;

  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    context.read<NotificationBloc>().add(
      const LoadNotificationsCacheFirstThenNetwork(''),
    );
    super.initState();
  }

  void _markAllAsRead(List<NotificationModel> notifications) {
    for (final notification in notifications) {
      if (notification.status == 'new') {
        context.read<NotificationBloc>().add(
          UpdateNotification(notification.copyWith(status: 'read')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<NotificationModel>>(
      valueListenable: sl<HiveNotificationService>().itemListener(),
      builder: (context, box, _) {
        final notifications = box.values.toList().cast<NotificationModel>();
        final sortedNotifications = [...notifications]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Scaffold(
          backgroundColor: context.canvasBackground,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: context.canvasBackground,
            foregroundColor: context.onCanvasText,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: const SizedBox(
              width: 40,
              height: 40,
              child: _BackButton(),
            ),
            title: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.onCanvasText,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => _markAllAsRead(sortedNotifications),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: context.mutedText,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Mark all as read'),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: ColoredBox(color: context.hairline.withValues(alpha: 0.7)),
            ),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            itemCount: sortedNotifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = sortedNotifications[index];
              switch (notification.type) {
                case "workOrderRequest":
                  return NotificationWorkOrderRequestWidget(
                    key: ValueKey(index),
                    notification: notification,
                    onDelete: () {
                      context.read<NotificationBloc>().add(
                        DeleteNotification(notification.uid!),
                      );
                    },
                    onTap: () {
                      if (notification.status != 'new') return;
                      final updateNotification = notification.copyWith(
                        status: 'read',
                      );
                      context.read<NotificationBloc>().add(
                        UpdateNotification(updateNotification),
                      );
                    },
                  );
                case "work_order_status_progress":
                  return NotificationWorkOrderStatusWidget(
                    key: ValueKey(index),
                    notification: notification,
                    onDelete: () {
                      context.read<NotificationBloc>().add(
                        DeleteNotification(notification.uid!),
                      );
                    },
                    onTap: () {
                      if (notification.status != 'new') return;
                      final updateNotification = notification.copyWith(
                        status: 'read',
                      );
                      context.read<NotificationBloc>().add(
                        UpdateNotification(updateNotification),
                      );
                    },
                  );
                default:
                  return NotificationInfoWidget(
                    key: ValueKey(index),
                    notification: notification,
                    onTap: () {
                      if (notification.status != 'new') return;
                      final updateNotification = notification.copyWith(
                        status: 'read',
                      );
                      context.read<NotificationBloc>().add(
                        UpdateNotification(updateNotification),
                      );
                    },
                  );
              }
            },
          ),
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.chevron_left, size: 24, color: context.onCanvasText),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}