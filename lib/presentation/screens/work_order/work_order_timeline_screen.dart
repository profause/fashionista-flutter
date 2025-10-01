import 'dart:io';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_status_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dartz/dartz.dart' as dartz;

class WorkOrderTimelineScreen extends StatefulWidget {
  final WorkOrderModel workOrderInfo; // 👈 workOrderInfo
  const WorkOrderTimelineScreen({super.key, required this.workOrderInfo});

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
      LoadWorkOrderProgressCacheFirstThenNetwork(widget.workOrderInfo.uid!),
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
                    case WorkOrderProgressLoaded(
                      :final workOrderProgress,
                      :final fromCache,
                    ):
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
                            onTap: () {},
                            isFirst: index == 0,
                            isLast: index == workOrderProgress.length - 1,
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
      ),
      floatingActionButton: SizedBox(
        height: 40, // default is 48
        child: FloatingActionButton.extended(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          onPressed: () {
            _showFilterBottomsheet(
              context,
              (statusProgress) => _onSaveProgress(statusProgress),
            );
          },
          label: Text(
            "Update timeline",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
        (r) {
          if (!mounted) return;
          context.read<WorkOrderStatusProgressBloc>().add(
            LoadWorkOrderProgressCacheFirstThenNetwork(
              widget.workOrderInfo.uid!,
            ),
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
                          child: ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
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
