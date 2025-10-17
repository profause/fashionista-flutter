import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_event.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/hive/hive_notification_service.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_info_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_work_order_request_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Notifications',
          style: textTheme.titleMedium!.copyWith(color: colorScheme.primary),
        ),
        elevation: 0,
      ),
      body: ValueListenableBuilder<Box<NotificationModel>>(
        valueListenable: sl<HiveNotificationService>().itemListener(),
        builder: (context, box, _) {
          final notifications = box.values.toList().cast<NotificationModel>();
          final sortedNotifications = [...notifications]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.separated(
            padding: const EdgeInsets.only(top: 2),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            separatorBuilder: (context, index) =>
                const Divider(height: .1, thickness: .1),
            itemCount: sortedNotifications.length,
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
                default:
                  return NotificationInfoWidget(
                    key: ValueKey(index),
                    notification: notification,
                  );
              }
            },
          );
        },
      ),

      // BlocBuilder<NotificationBloc, NotificationBlocState>(
      //   builder: (context, state) {
      //     switch (state) {
      //       case NotificationLoading():
      //         return const SizedBox(
      //           height: 400,
      //           child: Center(child: CircularProgressIndicator()),
      //         );

      //       case NotificationsLoaded(:final notifications):
      //         return ListView.separated(
      //           scrollDirection: Axis.vertical,
      //           shrinkWrap: true,
      //           separatorBuilder: (context, index) =>
      //               const Divider(height: .1, thickness: .1),
      //           itemCount: notifications.length,
      //           itemBuilder: (context, index) {
      //             final notification = notifications[index];
      //             switch (notification.type) {
      //               case "workOrderRequest":
      //                 return NotificationWorkOrderRequestWidget(
      //                   key: ValueKey(index),
      //                   notification: notification,
      //                 );
      //               default:
      //                 return NotificationInfoWidget(
      //                   key: ValueKey(index),
      //                   notification: notification,
      //                 );
      //             }
      //           },
      //         );
      //       case NotificationError(:final message):
      //         debugPrint(message);
      //         return Center(child: Text("Error: $message"));
      //       default:
      //         return Center(
      //           child: PageEmptyWidget(
      //             title: "No Notifications Found",
      //             subtitle: "",
      //             icon: Icons.notifications_none_outlined,
      //             iconSize: 48,
      //           ),
      //         );
      //     }
      //   },
      // ),
    );
  }
}
