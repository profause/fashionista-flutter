import 'package:fashionista/data/models/notification/bloc/notification_bloc.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_event.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_state.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        title: Text('Notifications', style: textTheme.titleMedium),
        elevation: 0,
      ),
      body: BlocBuilder<NotificationBloc, NotificationBlocState>(
        builder: (context, state) {
          switch (state) {
            case NotificationLoading():
              return const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator()),
              );

            case NotificationsLoaded(:final notifications):
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    child: ListTile(
                      title: Text(notification.title),
                      subtitle: Text(notification.description),
                    ),
                  );
                },
              );
            case NotificationError(:final message):
              debugPrint(message);
              return Center(child: Text("Error: $message"));
            default:
              return Center(
                child: PageEmptyWidget(
                  title: "No Notifications Found",
                  subtitle: "",
                  icon: Icons.notifications_none_outlined,
                  iconSize: 48,
                ),
              );
          }
        },
      ),
    );
  }
}
