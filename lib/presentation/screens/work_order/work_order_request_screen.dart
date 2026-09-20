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
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/firebase/firebase_user_service.dart';
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
  late ValueNotifier<bool> isMyClient = ValueNotifier(false);
  late bool isCheckingMyClient = false;
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
    final darkCanvas = context.canvasBackground;
    final darkCard = context.cardSurface;
    final darkSurface = context.secondaryButtonBg;
    final darkBorder = context.hairline;
    final textMuted = context.mutedText;
    final textDim = context.onCanvasText;
    final statusAmber = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF5C65C)
        : const Color(0xFFA83900);
    final statusDanger = Theme.of(context).colorScheme.error;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: context.onCanvasText,
        backgroundColor: darkCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 26,
            color: context.onCanvasText,
          ),
          splashRadius: 20,
          tooltip: 'Back',
        ),
        title: Text(
          'Work Order Request',
          style: textTheme.titleMedium!.copyWith(
            fontSize: 17,
            color: context.onCanvasText,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
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
              checkIfMyClient(workOrderInfo.client!.mobileNumber!);

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: darkCard,
                              border: Border.all(color: darkBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'CLIENT COMMUNICATION',
                                      style: textTheme.labelSmall!.copyWith(
                                        color: textMuted,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: darkBorder,
                                          width: 1,
                                        ),
                                        color: darkSurface,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            workOrderInfo.client!.avatar ?? '',
                                        fit: BoxFit.cover,
                                        alignment: const Alignment(0.0, 0.28),
                                        errorWidget: (context, url, error) =>
                                            DefaultProfileAvatar(
                                              name: null,
                                              size: 40,
                                              uid:
                                                  workOrderInfo.client!.uid ??
                                                  '',
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workOrderInfo.client!.name ??
                                                'Client',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: textTheme.titleSmall!
                                                .copyWith(
                                                  color: textDim,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            workOrderInfo
                                                    .client!
                                                    .mobileNumber ??
                                                '',
                                            style: textTheme.bodyMedium!
                                                .copyWith(color: textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ValueListenableBuilder<bool>(
                                  valueListenable: isMyClient,
                                  builder: (context, _, __) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              final Uri dialUri = Uri(
                                                scheme: 'tel',
                                                path: workOrderInfo
                                                    .client!
                                                    .mobileNumber!,
                                              );
                                              await launchUrl(
                                                dialUri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.phone_rounded,
                                              size: 16,
                                              color: context.accent,
                                            ),
                                            label: const Text('Call'),
                                            style: TextButton.styleFrom(
                                              backgroundColor: darkSurface,
                                              foregroundColor: textDim,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                side: BorderSide(
                                                  color: darkBorder,
                                                ),
                                              ),
                                              minimumSize:
                                                  const Size.fromHeight(40),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              final Uri messageUri = Uri(
                                                scheme: 'sms',
                                                path: workOrderInfo
                                                    .client!
                                                    .mobileNumber!,
                                              );
                                              await launchUrl(
                                                messageUri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 16,
                                              color: textDim,
                                            ),
                                            label: const Text('Message'),
                                            style: TextButton.styleFrom(
                                              backgroundColor: darkSurface,
                                              foregroundColor: textDim,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                side: BorderSide(
                                                  color: darkBorder,
                                                ),
                                              ),
                                              minimumSize:
                                                  const Size.fromHeight(40),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: darkCard,
                              border: Border.all(color: darkBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ORDER OVERVIEW',
                                      style: textTheme.labelMedium!.copyWith(
                                        color: textMuted,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.appIconColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.appIconColor
                                              .withValues(alpha: 0.22),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'Custom Tailoring',
                                        style: textTheme.labelSmall!.copyWith(
                                          color: AppTheme.appIconColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 112,
                                      height: 148,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: darkBorder),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            workOrderInfo.featuredMedia !=
                                                    null &&
                                                workOrderInfo
                                                    .featuredMedia!
                                                    .isNotEmpty &&
                                                workOrderInfo
                                                        .featuredMedia!
                                                        .first
                                                        .url !=
                                                    null
                                            ? CachedNetworkImage(
                                                imageUrl: workOrderInfo
                                                    .featuredMedia!
                                                    .first
                                                    .url!,
                                                fit: BoxFit.cover,
                                                alignment: const Alignment(
                                                  0.0,
                                                  0.40,
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const SizedBox.shrink(),
                                              )
                                            : Container(color: darkSurface),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TITLE',
                                            style: textTheme.labelSmall!
                                                .copyWith(
                                                  color: textMuted,
                                                  letterSpacing: 1.0,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            workOrderInfo.title,
                                            style: textTheme.titleSmall!
                                                .copyWith(
                                                  color: textDim,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'DESCRIPTION',
                                            style: textTheme.labelSmall!
                                                .copyWith(
                                                  color: textMuted,
                                                  letterSpacing: 1.0,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            workOrderInfo
                                                        .description
                                                        ?.isNotEmpty ==
                                                    true
                                                ? workOrderInfo.description!
                                                : 'No description provided.',
                                            maxLines: 7,
                                            overflow: TextOverflow.ellipsis,
                                            style: textTheme.bodySmall!
                                                .copyWith(
                                                  color: textMuted,
                                                  height: 1.5,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: darkCard,
                              border: Border.all(color: darkBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      4,
                                    ),
                                    child: Text(
                                      'SCHEDULE & PLANNING',
                                      style: textTheme.labelSmall!.copyWith(
                                        color: textMuted,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                _timelineRow(
                                  label: 'Start',
                                  value: workOrderInfo.startDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(workOrderInfo.startDate!)
                                      : 'no start date',
                                  trailing: Icon(
                                    Icons.calendar_month_outlined,
                                    color: textMuted,
                                    size: 20,
                                  ),
                                  textTheme: textTheme,
                                  mutedColor: textMuted,
                                  valueColor: textDim,
                                ),
                                Divider(height: 1, color: darkBorder),
                                _timelineRow(
                                  label: 'Due date',
                                  value: workOrderInfo.dueDate != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(workOrderInfo.dueDate!)
                                      : 'no due date',
                                  trailing: Icon(
                                    Icons.calendar_month_outlined,
                                    color: textMuted,
                                    size: 20,
                                  ),
                                  textTheme: textTheme,
                                  mutedColor: textMuted,
                                  valueColor: textDim,
                                ),
                                Divider(height: 1, color: darkBorder),
                                _timelineRow(
                                  label: 'Current progress',
                                  value: workOrderInfo.status ?? 'DRAFT',
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusAmber.withValues(
                                        alpha: 0.10,
                                      ),
                                      border: Border.all(
                                        color: statusAmber.withValues(
                                          alpha: 0.30,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: statusAmber,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Awaiting Confirmation',
                                          style: textTheme.labelSmall!.copyWith(
                                            color: statusAmber,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  textTheme: textTheme,
                                  mutedColor: textMuted,
                                  valueColor: const Color(0xFFF5C65C),
                                ),
                              ],
                            ),
                          ),
                          if (workOrderInfo.tags != null &&
                              workOrderInfo.tags!.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: workOrderInfo.tags!
                                    .split(',')
                                    .where((tag) => tag.trim().isNotEmpty)
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: darkSurface,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(color: darkBorder),
                                        ),
                                        child: Text(
                                          tag.trim(),
                                          style: textTheme.labelSmall!.copyWith(
                                            color: textDim,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        decoration: BoxDecoration(
                          color: darkCanvas,
                          border: Border(
                            top: BorderSide(color: darkBorder, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed:
                                    isMyClient.value || isCheckingMyClient
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
                                                onPressed: () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                                child: const Text('No'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: statusDanger,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (canCancel == true) {
                                          await _cancelWorkOrder(workOrderInfo);
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: statusDanger,
                                  backgroundColor: statusDanger.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: statusDanger),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  context.push(
                                    '/workorders/edit/${workOrderInfo.uid}',
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: textDim,
                                  backgroundColor: darkSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: darkBorder),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextButton(
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
                                                onPressed: () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      AppTheme.appIconColor,
                                                ),
                                                child: const Text('Accept'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (canAccept == true) {
                                          await _acceptWorkOrder(workOrderInfo);
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: context.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                  shadowColor: AppTheme.appIconColor.withValues(
                                    alpha: 0.35,
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Accept Request',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
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
                ],
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _timelineRow({
    required String label,
    required String value,
    required TextTheme textTheme,
    required Color mutedColor,
    required Color valueColor,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium!.copyWith(
                  color: mutedColor,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium!.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing,
        ],
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
          description:
              '${user.fullName} has accepted your work order - ${workOrderInfo.description}',
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

  Future<void> checkIfMyClient(String mobileNumber) async {
    isCheckingMyClient = true;
    final isMyClientResult = await sl<FirebaseClientsService>().isMyClient(
      mobileNumber,
    );

    isMyClientResult.fold(
      (l) {
        isMyClient.value = false;
      },
      (r) {
        isMyClient.value = r;
      },
    );
    isCheckingMyClient = false;
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

  @override
  void dispose() {
    super.dispose();
    _userBloc.close();
    isMyClient.dispose();
  }
}
