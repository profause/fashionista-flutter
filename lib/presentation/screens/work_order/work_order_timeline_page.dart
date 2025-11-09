import 'dart:io';

import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
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
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:fashionista/presentation/widgets/dotted_outline_button_widget.dart';
import 'package:fashionista/presentation/widgets/fullscreen_gallery_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
                child: Text(
                  textAlign: TextAlign.start,
                  'Stay on top of deadlines, updates, and progress — all in one place.',
                  style: textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: DottedOutlineButton(
                  label: 'Update timeline',
                  icon: Icons.update, // optional icon
                  iconColor: colorScheme.onSurfaceVariant,
                  width: double.infinity,
                  height: 45,
                  borderRadius: 12,
                  borderColor: colorScheme.onSurface.withValues(alpha: 0.3),
                  textStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
                        padding: EdgeInsets
                            .zero, // optional, since SliverList usually doesn't add padding
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
                      debugPrint(message);
                      return Center(child: Text("Error: $message"));
                    default:
                      return Center(
                        child: PageEmptyWidget(
                          title: "No prgress updates found",
                          subtitle:
                              "Provide details of the progress you have made so far.",
                          icon: Icons.work_history,
                          iconSize: 48,
                        ),
                      );
                  }
                },
              ),
            ],
          ),
        ),
      ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomTextInputFieldWidget(
                                  autofocus: true,
                                  controller: statusTextFieldController,
                                  hint:
                                      'Status... eg: knitting, cutting, sewing',
                                  validator: (value) {
                                    if ((value ?? "").isEmpty) {
                                      return 'Enter status of the project...';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const Divider(height: .1, thickness: .1),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomTextInputFieldWidget(
                                  autofocus: false,
                                  controller: descriptionTextFieldController,
                                  hint:
                                      'Describe the progress you have made so far...',
                                  minLines: 2,
                                  maxLength: 150,
                                  validator: (value) {
                                    if ((value ?? "").isEmpty) {
                                      return 'Describe the progress you have made so far...';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Featured images can help you share your progress with your clients.",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              if (previewImages.isNotEmpty) ...[
                                SizedBox(
                                  height: 200,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(8),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.file(
                                                File(image.path),
                                                //width: 180,
                                                //height: 180,
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
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
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
                              ],
                              if (previewImages.length < 2) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    CustomIconButtonRounded(
                                      onPressed: () {
                                        //if (true) return;
                                        _pickImages(context, (images) {
                                          //set images to previewImages[]
                                          setModalState(() {
                                            previewImages.addAll(images);
                                          });
                                        });
                                      },
                                      iconData: Icons.image_outlined,
                                    ),
                                    const SizedBox(width: 16),
                                    CustomIconButtonRounded(
                                      onPressed: () {
                                        _captureImage(ImageSource.camera, (
                                          image,
                                        ) {
                                          //set images to previewImages[]
                                          setModalState(() {
                                            previewImages.add(image);
                                          });
                                        });
                                      },
                                      iconData: Icons.camera_alt_outlined,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              //const Divider(height: .1, thickness: .1),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 4,
                            left: 8,
                            right: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Notify client",
                                style: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: notifyClient,
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
                          width: double.infinity, // takes full available width
                          height: 45,
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
                              elevation: 0,
                              backgroundColor:
                                  colorScheme.surface, // solid grey background
                              foregroundColor:
                                  colorScheme.onSurface, // text/icon color
                            ),
                            child: const Text("Save"),
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
                    Transformation().addTransformation('q_auto:low')
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
