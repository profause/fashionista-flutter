import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/firebase/firebase_user_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class WorkOrderRequestScreen extends StatefulWidget {
  final String workOrderRequestId;
  const WorkOrderRequestScreen({super.key, required this.workOrderRequestId});

  @override
  State<WorkOrderRequestScreen> createState() => _WorkOrderRequestScreenState();
}

class _WorkOrderRequestScreenState extends State<WorkOrderRequestScreen> {
  late WorkOrderModel workOrderInfo;
  late UserBloc _userBloc;
  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    context.read<WorkOrderBloc>().add(
      LoadWorkOrder(widget.workOrderRequestId, isFromCache: false),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = 28.0;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Work Order Request',
          style: textTheme.titleMedium!.copyWith(color: colorScheme.primary),
        ),
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
        buildWhen: (context, state) {
          return state is WorkOrderLoaded ||
              state is WorkOrderLoading ||
              state is WorkOrderUpdated;
        },
        builder: (context, state) {
          switch (state) {
            case WorkOrderLoading():
              return const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );

            case WorkOrderError():
              return Center(child: Text(state.message));
            case WorkOrderLoaded(:final workorder):
            case WorkOrderUpdated(:final workorder):
              workOrderInfo = workorder;
              final isRequest = workorder.workOrderType == 'REQUEST';
              final isCancelled = workorder.status == 'CANCELLED';
              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: radius,
                                backgroundColor: colorScheme.surface,
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: workOrderInfo.client!.avatar!,
                                    errorListener: (error) {},
                                    errorWidget: (context, url, error) =>
                                        DefaultProfileAvatar(
                                          name: null,
                                          size: radius * 2,
                                          uid: workOrderInfo.client!.uid!,
                                        ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            workOrderInfo.client!.name!,
                                            style: textTheme.titleSmall!
                                                .copyWith(
                                                  color: colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 0),
                                      Text(
                                        workOrderInfo.client!.mobileNumber!,
                                        style: textTheme.bodyMedium!.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.person_rounded),
                                label: const Text('Add as client'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),

                              // 🔹 Vertical divider between buttons
                              Container(
                                height: 24, // control height
                                width: 1,
                                color: Colors.grey.withValues(alpha: 0.4),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),

                              OutlinedButton.icon(
                                onPressed: () async {
                                  final Uri dialUri = Uri(
                                    scheme: 'tel',
                                    path: workOrderInfo.client!.mobileNumber!,
                                  );
                                  await launchUrl(
                                    dialUri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.call_rounded),
                                label: const Text('Contact client'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green.withValues(
                                  alpha: 0.2,
                                ),
                                disabledBackgroundColor: colorScheme.surface,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: !isRequest
                                  ? null
                                  : () async {
                                      final canAccept = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Accept Work Order',
                                          ),
                                          content: const Text(
                                            'Are you sure you want to accept this work order?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.green,
                                              ),
                                              child: const Text('Accept'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (canAccept == true) {
                                        await _acceptWorkOrder(workorder);
                                      }
                                    },
                              child: Text(
                                !isRequest ? 'Accepted' : 'Accept',
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blueAccent.withValues(
                                  alpha: 0.2,
                                ),
                                disabledBackgroundColor: colorScheme.surface,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: isCancelled
                                  ? null
                                  : () {
                                      context.push(
                                        '/workorders/edit/${workOrderInfo.uid}',
                                      );
                                    },
                              child: Text(
                                "Edit",
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            //const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: AppTheme.appIconColor
                                    .withValues(alpha: 0.2),
                                disabledBackgroundColor: colorScheme.surface,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: isCancelled
                                  ? null
                                  : () async {
                                      final canCancel = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Cancel Request'),
                                          content: const Text(
                                            'Are you sure you want to cancel this request?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (canCancel == true) {
                                        await _cancelWorkOrder(workorder);
                                      }
                                    },
                              child: Text(
                                "Cancel",
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (workOrderInfo.featuredMedia!.isNotEmpty)
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 8,
                            top: 12,
                          ),
                          itemCount: workOrderInfo.featuredMedia!.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final image =
                                workOrderInfo.featuredMedia![index].url;
                            return Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 3 / 4,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: image!.isEmpty
                                          ? ''
                                          : image.trim(),
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const CustomColoredBanner(text: ''),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Title"),
                                Text(
                                  workOrderInfo.title,
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: .1, thickness: .1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Description"),
                                Text(
                                  workOrderInfo.description ?? "",
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date Pickers
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Start"),
                                Text(
                                  workOrderInfo.startDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(workOrderInfo.startDate!)
                                      : 'no start date',
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: .1, thickness: .1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Due date"),
                                Text(
                                  workOrderInfo.dueDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(workOrderInfo.dueDate!)
                                      : 'no due date',
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Current progress"),
                                    Text(
                                      workOrderInfo.status!,
                                      style: textTheme.bodyMedium!.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          //const Divider(height: .1, thickness: .1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (workOrderInfo.tags!.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.only(left: 12, bottom: 16),
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            workOrderInfo.tags!.split(',').length,
                            (index) => Chip(
                              label: Text(
                                workOrderInfo.tags!.split(',')[index],
                              ),
                              padding: EdgeInsets.zero, // remove extra padding
                              visualDensity:
                                  VisualDensity.compact, // tighter look
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                      //const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              );
            default:
              return SizedBox.shrink();
          }
        },
      ),
    );
  }

  Future<void> _acceptWorkOrder(WorkOrderModel workOrderInfo) async {
    if (mounted) {
      showLoadingDialog(context);
    }
    final updated = workOrderInfo.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      workOrderType: 'DRAFT',
      status: 'DRAFT',
    );
    context.read<WorkOrderBloc>().add(UpdateWorkOrder(updated));
    User user = _userBloc.state;
    final userResult = await sl<FirebaseUserService>().findUserByMobileNumber(
      workOrderInfo.client!.mobileNumber!,
    );

    userResult.fold(
      (l) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      (r) async {
        //send notification to user who created the client
        final authorUser = AuthorModel.empty().copyWith(
          uid: user.uid,
          name: user.fullName,
          avatar: user.profileImage,
          mobileNumber: user.mobileNumber,
        );

        final notification = NotificationModel.empty().copyWith(
          uid: Uuid().v4(),
          title: 'Work Order Update',
          description: '${user.fullName} has accepted your work order - ${workOrderInfo.description}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          type: 'work_order_status_progress',
          refId: workOrderInfo.uid,
          refType: "work_order_status_progress",
          from: user.uid,
          to: r.uid,
          author: authorUser,
          status: 'new',
        );

        await sl<FirebaseNotificationService>().createNotification(
          notification,
        );
      },
    );

    if (!mounted) return;
    dismissLoadingDialog(context);
    //context.pop(); // notify ClientsScreen
  }

  Future<void> _cancelWorkOrder(WorkOrderModel workOrderInfo) async {
    if (mounted) {
      showLoadingDialog(context);
    }
    final updated = workOrderInfo.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      workOrderType: 'REQUEST',
      status: 'CANCELLED',
    );
    context.read<WorkOrderBloc>().add(UpdateWorkOrder(updated));

    if (!mounted) return;
    dismissLoadingDialog(context);
    //context.pop(); // notify ClientsScreen
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
