import 'dart:io';

import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_1.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_2.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_3.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_4.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class EditWorkOrderScreen extends StatefulWidget {
  final String workOrderId;
  const EditWorkOrderScreen({super.key, required this.workOrderId});

  @override
  State<EditWorkOrderScreen> createState() => _EditWorkOrderScreenState();
}

class _EditWorkOrderScreenState extends State<EditWorkOrderScreen> {
  final PageController _pageController = PageController();
  late UserBloc _userBloc;
  late WorkOrderModel workOrder;

  @override
  void initState() {
    super.initState();
    context.read<WorkOrderBloc>().add(
      LoadWorkOrder(widget.workOrderId, isFromCache: false),
    );
    _pageController.addListener(() {});
    _userBloc = context.read<UserBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Edit Work Order',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
        buildWhen: (context, state) {
          return state is WorkOrderLoaded || state is WorkOrderLoading;
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
            case WorkOrderLoaded():
              workOrder = state.workorder;
              final pages = [
                WorkOrderFlowPage1(
                  onNext: () => nextPage(),
                  workOrder: workOrder,
                ),
                WorkOrderFlowPage2(
                  onNext: () => nextPage(),
                  onPrev: () => prevPage(),
                ),
                WorkOrderFlowPage3(
                  onNext: () => nextPage(),
                  onPrev: () => prevPage(),
                ),
                WorkOrderFlowPage4(
                  onNext: (workOrder) => onSave(workOrder),
                  onPrev: () => prevPage(),
                ),
              ];
              return SafeArea(
                //tag: "getStartedButton",
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: pages.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return pages[index];
                        },
                      ),
                    ),
                  ],
                ),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  void nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void onSave(WorkOrderModel workorder) async {
    try {
      User user = _userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      final workOrderId = workorder.uid ?? Uuid().v4();

      List<FeaturedMediaModel> featuredImages = [];
      List<XFile> pickedImages = [];
      if (workorder.featuredMedia!.isNotEmpty) {
        for (var i = 0; i < workorder.featuredMedia!.length; i++) {
          final imagePath = workorder.featuredMedia![i].url;
          if (imagePath!.startsWith('http')) {
            featuredImages.add(workorder.featuredMedia![i]);
          } else {
            pickedImages.add(XFile(workorder.featuredMedia![i].url!));
          }
        }
      }
      // Show progress dialog
      showLoadingDialog(context);

      if (pickedImages.isNotEmpty) {
        final uploadResult = await uploadImagesToCloudinary(
          context,
          workOrderId,
          pickedImages,
          featuredImages.length,
        );

        uploadResult.fold(
          (ifLeft) {
            // _buttonLoadingStateCubit.setLoading(false);
            if (mounted) {
              //Navigator.of(context).pop();
            }
            // debugPrint(ifLeft);
            // ScaffoldMessenger.of(
            //   context,
            // ).showSnackBar(SnackBar(content: Text(ifLeft)));
            return;
          },
          (ifRight) {
            //_buttonLoadingStateCubit.setLoading(false);
            featuredImages.addAll(ifRight);
            setState(() {
              //isUploading = false;
            });
          },
        );
      }
      AuthorModel author =
          workorder.author ??
          AuthorModel.empty().copyWith(
            uid: createdBy,
            name: user.fullName,
            avatar: user.profileImage,
          );

      if (author.uid!.isEmpty) {
        author = author.copyWith(
          uid: createdBy,
          name: user.fullName,
          avatar: user.profileImage,
        );
      }

      workorder = workorder.copyWith(
        createdBy: createdBy,
        uid: workOrderId,
        featuredMedia: featuredImages,
        createdAt: workorder.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt: workorder.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
        status: 'DRAFT',
        workOrderType: workorder.workOrderType ?? '',
        author: author,
      );

      if (mounted) {
        context.read<WorkOrderBloc>().add(UpdateWorkOrder(workorder));
        dismissLoadingDialog(context);
        context.pop(); //
      }
    } on firebase_auth.FirebaseException catch (e) {
      //_buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<dartz.Either<String, List<FeaturedMediaModel>>>
  uploadImagesToCloudinary(
    BuildContext context,
    String workOrderId,
    List pickedImages,
    int count,
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

    // Step 1: Collect aspect ratios + prepare upload tasks

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      final uploadFile = File(image.path);

      // Get aspect ratio
      final aspect = await getImageAspectRatio(image);
      aspects.add(aspect);
      int index = count + i;
      final fileName = "${workOrderId}_$index.jpg";
      final publicId = "${workOrderId}_$index";

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
