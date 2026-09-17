import 'dart:io';

import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/firebase/firebase_user_service.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_status_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/dotted_outline_button_widget.dart';
import 'package:fashionista/presentation/widgets/fullscreen_gallery_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dartz/dartz.dart' as dartz;
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class WorkOrderTimelinePage extends StatefulWidget {
  final WorkOrderModel workOrderInfo; // 👈 workOrderInfo
  const WorkOrderTimelinePage({super.key, required this.workOrderInfo});

  @override
  State<WorkOrderTimelinePage> createState() => _WorkOrderTimelinePageState();
}

class _WorkOrderTimelinePageState extends State<WorkOrderTimelinePage> {
  final ImagePicker picker = ImagePicker();
  late UserBloc _userBloc;

  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    context.read<WorkOrderStatusProgressBloc>().add(
      LoadStatusProgress(widget.workOrderInfo.uid!),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    //border: Border.all(color: context.hairline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.accent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: context.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Stay on top of deadlines, updates, and production '
                          'progress — all in one unified space.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: context.descriptionText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: DottedOutlineButton(
                  label: 'Update Production Timeline',
                  icon: Icons.update,
                  iconColor: context.accent,
                  iconSize: 18,
                  width: double.infinity,
                  height: 52,
                  borderRadius: 16,
                  strokeWidth: 1.5,
                  borderColor: context.accent,
                  backgroundColor: context.cardSurface,
                  textStyle: TextStyle(
                    color: context.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                  onPressed: () {
                    _showTimelineBottomsheet(
                      context,
                      (statusProgress) => _onSaveProgress(statusProgress),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<
                WorkOrderStatusProgressBloc,
                WorkOrderStatusProgressBlocState
              >(
                builder: (context, state) {
                  switch (state) {
                    case WorkOrderProgressLoading():
                      return const SizedBox(
                        height: 400,
                        child: Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    case WorkOrderProgressLoaded(:final workOrderProgress):
                      return ListView.separated(
                        shrinkWrap: true, // 👈 fixes unbounded height
                        physics:
                            NeverScrollableScrollPhysics(), // 👈 disable inner scrolling
                        padding: const EdgeInsets
                            .symmetric(horizontal: 16), // optional, since SliverList usually doesn't add padding
                            
                        itemBuilder: (context, index) {
                          final statusProgress = workOrderProgress[index];
                          return WorkOrderStatusInfoCardWidget(
                            workOrderStatusInfo: statusProgress,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullscreenGalleryWidget(
                                    images: statusProgress.featuredMedia!
                                        .map((e) => e.url!)
                                        .toList(),
                                    initialIndex: 0,
                                  ),
                                ),
                              );
                            },
                            isFirst: index == 0,
                            isLast: index == workOrderProgress.length - 1,
                            onDelete: () async {
                              final canDelete = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Timeline status'),
                                  content: const Text(
                                    'Are you sure you want to delete this item?',
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
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (canDelete == true) {
                                _deleteStatusProgress(statusProgress);
                              }
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 0),
                        itemCount: workOrderProgress.length,
                      );
                    case WorkOrderProgressError(:final message):
                      //debugPrint(message);
                      return Center(child: Text("Error: $message"));
                    case WorkOrderProgressEmpty():
                      return _buildEmptyState(context);
                    default:
                      return _buildEmptyState(context);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.accent.withValues(alpha: 0.05),
                border: Border.all(
                  color: context.accent.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(Icons.work_history, size: 36, color: context.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'No Progress Updates Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: context.onCanvasText,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: Text(
                'Provide logged details of the custom tailoring updates you have '
                'executed so far to keep your client informed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.mutedText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                _showTimelineBottomsheet(
                  context,
                  (statusProgress) => _onSaveProgress(statusProgress),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                backgroundColor: context.accent,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: context.accent.withValues(alpha: 0.25),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 8),
                  Text('Log First Update'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSaveProgress(WorkOrderStatusProgressModel statusProgress) async {
    try {
      User user = _userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      final statusProgressId = Uuid().v4();

      List<FeaturedMediaModel> featuredImages = [];
      List<XFile> pickedImages = [];
      if (statusProgress.featuredMedia!.isNotEmpty) {
        for (var i = 0; i < statusProgress.featuredMedia!.length; i++) {
          pickedImages.add(XFile(statusProgress.featuredMedia![i].url!));
        }
      }
      // Show progress dialog
      showLoadingDialog(context);

      final uploadResult = await uploadImagesToCloudinary(
        context,
        statusProgressId,
        pickedImages,
      );

      uploadResult.fold(
        (ifLeft) {
          // _buttonLoadingStateCubit.setLoading(false);
          dismissLoadingDialog(context);
          debugPrint(ifLeft);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
          return;
        },
        (ifRight) {
          featuredImages = ifRight;
        },
      );

      statusProgress = statusProgress.copyWith(
        createdBy: createdBy,
        uid: statusProgressId,
        featuredMedia: featuredImages,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        workOrderId: widget.workOrderInfo.uid,
      );

      // Save via FirebaseWorkOrderService
      final result = await sl<FirebaseWorkOrderService>()
          .createWorkOrderStatusProgress(statusProgress);

      result.fold(
        (l) {
          if (mounted) {
            Navigator.of(context).pop();
          }
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) async {
          if (!mounted) return;
          context.read<WorkOrderStatusProgressBloc>().add(
            LoadStatusProgress(widget.workOrderInfo.uid!),
          );

          if (statusProgress.notifyClient == true) {
            final userResult = await sl<FirebaseUserService>()
                .findUserByMobileNumber(
                  widget.workOrderInfo.client!.mobileNumber!,
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
                  description: '${statusProgress.description}',
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  type: 'work_order_status_progress',
                  refId: widget.workOrderInfo.uid,
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
          }
          if (mounted) {
            dismissLoadingDialog(context);
            Navigator.pop(context);
          }
        },
      );
    } on firebase_auth.FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  void _showTimelineBottomsheet(
    BuildContext context,
    Function(WorkOrderStatusProgressModel statusProgress) onSave,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final TextEditingController statusTextFieldController =
        TextEditingController();
    final TextEditingController descriptionTextFieldController =
        TextEditingController();

    List<XFile> previewImages = [];

    WorkOrderStatusProgressModel statusProgressModel =
        WorkOrderStatusProgressModel.empty();

    bool notifyClient = statusProgressModel.notifyClient ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.7,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Handle bar
                        Center(
                          child: Container(
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Text(
                          "Provide details of the progress you have made so far.",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            //border: Border.all(color: context.hairline),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: statusTextFieldController,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Status... e.g. knitting, cutting, sewing',
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: context.placeholderText,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(minHeight: 110),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            //border: Border.all(color: context.hairline),
                          ),
                          child: TextField(
                            controller: descriptionTextFieldController,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 150,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText:
                                  'Describe the progress you have made so far...',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: context.placeholderText,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              counterStyle: textTheme.bodySmall?.copyWith(
                                color: context.mutedText,
                                fontSize: 12,
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Featured Images',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: context.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share real-time workshop progress with your clients.',
                          style: textTheme.bodySmall?.copyWith(
                            color: context.mutedText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (previewImages.isNotEmpty) ...[
                          SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: previewImages.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final image = previewImages[index];
                                return Stack(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 3 / 4,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(image.path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            previewImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black54,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (previewImages.length < 2)
                          Container(
                            height: 72,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              //border: Border.all(color: context.hairline),
                            ),
                            child: Row(
                              children: [
                                _buildMediaButton(
                                  context: context,
                                  icon: Icons.image_outlined,
                                  tooltip: 'Upload Photo',
                                  onPressed: () {
                                    _pickImages(context, (images) {
                                      setModalState(() {
                                        previewImages.addAll(images);
                                      });
                                    });
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildMediaButton(
                                  context: context,
                                  icon: Icons.camera_alt_outlined,
                                  tooltip: 'Open Camera',
                                  onPressed: () {
                                    _captureImage(ImageSource.camera, (image) {
                                      setModalState(() {
                                        previewImages.add(image);
                                      });
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            //border: Border.all(color: context.hairline),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Notify client',
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Switch(
                                value: notifyClient,
                                activeTrackColor: context.accent,
                                activeThumbColor: Colors.white,
                                onChanged: (value) {
                                  setModalState(() {
                                    notifyClient = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              if (previewImages.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please upload at least one image',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (statusTextFieldController.text
                                  .trim()
                                  .isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Status of the project is required',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (descriptionTextFieldController.text
                                  .trim()
                                  .isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Describe the progress you have made so far',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final featuredMedia = previewImages.map((e) {
                                return FeaturedMediaModel.empty().copyWith(
                                  url: e.path,
                                  type: 'image',
                                );
                              }).toList();
                              final statusProgress = statusProgressModel
                                  .copyWith(
                                    status: statusTextFieldController.text
                                        .trim(),
                                    description: descriptionTextFieldController
                                        .text
                                        .trim(),
                                    featuredMedia: featuredMedia,
                                    notifyClient: notifyClient,
                                  );

                              onSave(statusProgress);
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: context.accent.withValues(
                                alpha: 0.3,
                              ),
                              backgroundColor: context.accent,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Save Progress Update'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMediaButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: context.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 20, color: context.onCanvasText),
          ),
        ),
      ),
    );
  }

  Future<dartz.Either<String, List<FeaturedMediaModel>>>
  uploadImagesToCloudinary(
    BuildContext context,
    String workOrderId,
    List pickedImages,
  ) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');

    CloudinaryConfig config = CloudinaryConfig.fromUri(
      appConfig.get('cloudinary_url'),
    );
    final workOrderMediaFolder = appConfig.get(
      'cloudinary_work_order_images_folder',
    );
    final baseFolder = appConfig.get('cloudinary_base_folder');

    final cloudinary = Cloudinary.fromConfiguration(config);

    final uploadTasks = <Future<FeaturedMediaModel>>[];

    final aspects = <double?>[];

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      final uploadFile = File(image.path);

      // Get aspect ratio
      final aspect = await getImageAspectRatio(image);
      aspects.add(aspect);

      final fileName = "${workOrderId}_$i.jpg";
      final publicId = "${workOrderId}_$i";

      final transformation = Transformation()
          .resize(Resize.auto().width(480).aspectRatio(aspect))
          .addTransformation('q_60');
      // Define upload task returning a non-null String
      final uploadTask = (() async {
        final uploadResult = await cloudinary.uploader().upload(
          uploadFile,
          params: UploadParams(
            filename: fileName,
            publicId: publicId,
            useFilename: true,
            folder: '$baseFolder/$workOrderMediaFolder',
            uploadPreset: 'ml_default',
            type: 'image/jpeg',
            transformation: transformation,
          ),
        );

        if (uploadResult == null) {
          debugPrint("Upload failed — no response from Cloudinary");
          throw Exception("Upload failed — no response from Cloudinary");
        }
        if (uploadResult.error != null) {
          debugPrint("Upload failed: ${uploadResult.error!.message}");
          throw Exception(uploadResult.error!.message);
        }

        final url = uploadResult.data?.secureUrl;
        if (url == null) {
          debugPrint("Upload failed — no URL returned");
          throw Exception("Upload failed — no URL returned");
        }

        String thumbnailUrl =
            (cloudinary.image('$baseFolder/$workOrderMediaFolder/$fileName')
                  ..transformation(
                    Transformation().addTransformation('q_auto:eco')
                      ..resize(Resize.auto().width(360).aspectRatio(aspect)),
                  ))
                .toString();
        final featuredMedia = FeaturedMediaModel().copyWith(
          url: url,
          type: "image",
          aspectRatio: aspect,
          thumbnailUrl: thumbnailUrl,
          uid: '$baseFolder/$workOrderMediaFolder/$publicId',
        );
        return featuredMedia; // ✅ Non-null String
      })();

      uploadTasks.add(uploadTask);
    }

    try {
      // Wait for all uploads to finish
      final featuredMedia = await Future.wait(uploadTasks); // List<String>
      final mergedList = featuredMedia;

      return dartz.Right(mergedList);
    } catch (e) {
      return dartz.Left(e.toString());
    }
  }

  Future<void> _captureImage(
    ImageSource source,
    Function(XFile image) onImagePicked,
  ) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      onImagePicked(pickedFile);
    }
    if (mounted) {
      // Dismiss the dialog manually
      //Navigator.of(context, rootNavigator: true).pop();
    }
    //_cropImage();
  }

  Future<void> _pickImages(
    BuildContext context,
    Function(List<XFile> pickedImages) onImagePicked,
  ) async {
    final images = await picker.pickMultiImage(
      imageQuality: 70,
      limit: 3,
      requestFullMetadata: true,
    );
    if (images.isEmpty) return;
    onImagePicked(images);
  }

  Future<void> _deleteStatusProgress(
    WorkOrderStatusProgressModel statusProgress,
  ) async {
    try {
      // create a dynamic list of futures
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final List<Future<dartz.Either>> futures = statusProgress.featuredMedia!
          .map((e) => sl<FirebaseClosetService>().deleteClosetItemImage(e.url!))
          .toList();

      // also add delete by id
      futures.add(
        sl<FirebaseWorkOrderService>().deleteWorkOrderStatusProgress(
          statusProgress.uid!,
        ),
      );

      // wait for all and capture results
      final results = await Future.wait(futures);

      // handle each result
      for (final result in results) {
        result.fold(
          (failure) {
            // handle failure
            debugPrint("Delete failed: $failure");
          },
          (success) {
            // handle success
          },
        );
      }

      if (!mounted) return;
      context.read<WorkOrderStatusProgressBloc>().add(
        DeleteWorkOrderProgress(statusProgress),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
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
