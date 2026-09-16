import 'dart:io';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_status_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/fullscreen_gallery_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dartz/dartz.dart' as dartz;

class WorkOrderTimelineScreen extends StatefulWidget {
  final String workOrderId; // 👈 workOrderInfo
  const WorkOrderTimelineScreen({super.key, required this.workOrderId});

  @override
  State<WorkOrderTimelineScreen> createState() =>
      _WorkOrderTimelineScreenState();
}

class _WorkOrderTimelineScreenState extends State<WorkOrderTimelineScreen> {
  final ImagePicker picker = ImagePicker();
  late UserBloc _userBloc;

  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    context.read<WorkOrderStatusProgressBloc>().add(
      LoadStatusProgress(widget.workOrderId),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text('Project Timeline'),
        elevation: 0,
      ),
      body: SafeArea(
        // 👈 makes sure it stays below status bar
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, right: 16),
                child: Text(
                  textAlign: TextAlign.start,
                  'Stay on top of deadlines, updates, and progress — all in one place.',
                  style: textTheme.titleSmall,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 0),
                        itemCount: workOrderProgress.length,
                      );
                    case WorkOrderProgressError(:final message):
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
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uploadResult = await uploadImages(
        context,
        statusProgressId,
        pickedImages,
      );

      uploadResult.fold(
        (ifLeft) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            Navigator.of(context).pop();
          }
          debugPrint(ifLeft);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
          return;
        },
        (ifRight) {
          //_buttonLoadingStateCubit.setLoading(false);
          featuredImages = ifRight;
          setState(() {
            //isUploading = false;
          });
        },
      );

      statusProgress = statusProgress.copyWith(
        createdBy: createdBy,
        uid: statusProgressId,
        featuredMedia: featuredImages,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        workOrderId: widget.workOrderId,
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
        (r) {
          if (!mounted) return;
          context.read<WorkOrderStatusProgressBloc>().add(
            LoadStatusProgress(widget.workOrderId),
          );
          Navigator.pop(context);
          Navigator.pop(context);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Work Order created successfully!')),
          // );
        },
      );
    } on firebase_auth.FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  void _showFilterBottomsheet(
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
                            border: Border.all(color: context.hairline),
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
                                    isDense: true,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: context.secondaryLabel,
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
                            border: Border.all(color: context.hairline),
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
                                        borderRadius:
                                            BorderRadius.circular(12),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.hairline),
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
                            border: Border.all(color: context.hairline),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Notify client via SMS',
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

  Future<dartz.Either<String, List<FeaturedMediaModel>>> uploadImages(
    BuildContext context,
    String workOrderId,
    List pickedImages,
  ) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');

    final storage = FirebaseStorage.instance;
    final uploadTasks = <Future<String>>[];
    final aspects = <double?>[];

    // Step 1: Collect aspect ratios + prepare upload tasks
    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];

      // get aspect ratio
      final aspect = await getImageAspectRatio(image);
      aspects.add(aspect);

      // prepare upload
      uploadTasks.add(() async {
        final fileName = "${workOrderId}_$i.jpg";
        final ref = storage.ref().child("work_order_images/$fileName");

        final uploadTask = ref.putFile(File(image.path));
        await uploadTask;
        return await ref.getDownloadURL();
      }());
    }

    try {
      // Step 2: Upload all + get URLs
      final urls = await Future.wait(uploadTasks);

      // Step 3: Merge into FeaturedMediaModel list
      final mergedList = List.generate(
        urls.length,
        (i) => FeaturedMediaModel(
          url: urls[i],
          type: "image", // could be "video" if needed
          aspectRatio: aspects[i],
        ),
      );

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("✅ Images uploaded successfully!")),
      // );
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
      limit: 4,
      requestFullMetadata: true,
    );
    if (images.isEmpty) return;
    onImagePicked(images);
  }
}
