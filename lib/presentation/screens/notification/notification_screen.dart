import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_event.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_state.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_booking_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_review_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_trend_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_info_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_work_order_request_widget.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_work_order_status_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Distance from the bottom that triggers the next page.
  static const double _loadMoreThreshold = 300;

  /// List length the last viewport fill ran for.
  ///
  /// Prevents the post-frame check from re-dispatching on every state change
  /// (which would loop while a page is in flight or after a failure).
  int? _autoFilledLength;

  @override
  void initState() {
    context.read<NotificationBloc>().add(
      const LoadNotificationsPage(''),
    );
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > _loadMoreThreshold) return;

    // Every scroll tick lands here, so only fire when the bloc can accept a
    // page: otherwise a failing page is retried on each tick, which clears the
    // error row before the user can read it. Failures wait for the Retry tap.
    final state = context.read<NotificationBloc>().state;
    if (state is! NotificationsLoaded) return;
    if (!state.hasMore || state.isLoadingMore || state.loadMoreError != null) {
      return;
    }

    context.read<NotificationBloc>().add(const LoadMoreNotifications());
  }

  /// A first page shorter than the viewport can never scroll, so the listener
  /// above would never fire. Fill the screen once after the first frame.
  void _fillViewport() {
    final loaded = context.read<NotificationBloc>().state;
    if (loaded is! NotificationsLoaded) return;
    if (!loaded.hasMore || loaded.isLoadingMore) return;
    if (loaded.loadMoreError != null) return;
    if (_autoFilledLength == loaded.notifications.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final position = _scrollController.position;
      if (!position.hasContentDimensions || position.maxScrollExtent > 0) return;

      _autoFilledLength = loaded.notifications.length;
      context.read<NotificationBloc>().add(const LoadMoreNotifications());
    });
  }

  void _markAllAsRead() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    // One batched Firestore write instead of one call per notification.
    context.read<NotificationBloc>().add(MarkAllNotificationsRead(uid));
  }

  Future<void> _refresh() async {
    _autoFilledLength = null;
    context.read<NotificationBloc>().add(
      const LoadNotificationsPage('', refresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationBlocState>(
      listener: (context, state) {
        // Fill the screen when the first page does not overflow it.
        if (state is NotificationsLoaded) _fillViewport();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.canvasBackground,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            backgroundColor: context.canvasBackground,
            foregroundColor: context.onCanvasText,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            // leading: const SizedBox(
            //   width: 40,
            //   height: 40,
            //   child: _BackButton(),
            // ),
            title: Text(
              'Notifications',
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => _markAllAsRead(),
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
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationBlocState state) {
    if (state is NotificationLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is NotificationError) {
      return _ErrorState(
        message: state.message,
        onRetry: _refresh,
      );
    }

    if (state is NotificationsEmpty) {
      return _EmptyState(onRefresh: _refresh);
    }

    final notifications = state is NotificationsLoaded
        ? state.notifications
        : const <NotificationModel>[];

    if (notifications.isEmpty) {
      return _EmptyState(onRefresh: _refresh);
    }

    final loaded = state as NotificationsLoaded;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        // One extra row carries the bottom loader, the retry action or nothing.
        itemCount: notifications.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return _FooterSlot(
              isLoadingMore: loaded.isLoadingMore,
              error: loaded.loadMoreError,
              hasMore: loaded.hasMore,
              onRetry: () => context.read<NotificationBloc>().add(
                const LoadMoreNotifications(),
              ),
            );
          }

              final notification = notifications[index];
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
                case "appointment":
                // `booking` is the legacy value on already-stored records.
                case "booking":
                  return NotificationBookingWidget(
                    key: ValueKey(index),
                    notification: notification,
                    onDelete: () {
                      context.read<NotificationBloc>().add(
                        DeleteNotification(notification.uid!),
                      );
                    },
                    onTap: () {
                      if (notification.status != 'new') return;
                      context.read<NotificationBloc>().add(
                        UpdateNotification(
                          notification.copyWith(status: 'read'),
                        ),
                      );
                    },
                  );
                case "trend":
                case "trend_like":
                  return NotificationTrendWidget(
                    key: ValueKey(index),
                    notification: notification,
                    onDelete: () {
                      context.read<NotificationBloc>().add(
                        DeleteNotification(notification.uid!),
                      );
                    },
                    onTap: () {
                      if (notification.status != 'new') return;
                      context.read<NotificationBloc>().add(
                        UpdateNotification(
                          notification.copyWith(status: 'read'),
                        ),
                      );
                    },
                  );
                  //create a new widget for the notification type "review" and handle it here
                case "review":
                case "designer_review":
                  return NotificationReviewWidget(
                    key: ValueKey(index),
                    notification: notification,
                    onDelete: () {
                      context.read<NotificationBloc>().add(
                        DeleteNotification(notification.uid!),
                      );
                    },
                    onTap: () {
                      if (notification.status != 'new') return;
                      context.read<NotificationBloc>().add(
                        UpdateNotification(
                          notification.copyWith(status: 'read'),
                        ),
                      );
                    },
                  );
                  //create a new widget for the notification type "comment" and handle it here
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
  }
}

/// Spinner, retry or an empty spacer at the end of the feed.
class _FooterSlot extends StatelessWidget {
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final VoidCallback onRetry;

  const _FooterSlot({
    required this.isLoadingMore,
    required this.error,
    required this.hasMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Could not load more',
              style: TextStyle(fontSize: 13, color: context.mutedText),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: context.placeholderText,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(fontSize: 15, color: context.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.mutedText),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
