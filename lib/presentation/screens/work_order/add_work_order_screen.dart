import 'dart:io';

import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_1.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_2.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_3.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_4.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class AddWorkOrderScreen extends StatefulWidget {
  const AddWorkOrderScreen({super.key});

  @override
  State<AddWorkOrderScreen> createState() => _AddWorkOrderScreenState();
}

class _AddWorkOrderScreenState extends State<AddWorkOrderScreen> {
  final PageController _pageController = PageController();
  late UserBloc _userBloc;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {});
    _userBloc = context.read<UserBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      WorkOrderFlowPage1(onNext: () => nextPage()),
      WorkOrderFlowPage2(onNext: () => nextPage(), onPrev: () => prevPage()),
      WorkOrderFlowPage3(onNext: () => nextPage(), onPrev: () => prevPage()),
      WorkOrderFlowPage4(
        onNext: (workOrder) => onSave(workOrder),
        onPrev: () => prevPage(),
      ),
    ];
    return BlocProvider(
      create: (_) => WorkOrderBloc(),
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: colorScheme.primary,
          backgroundColor: colorScheme.onPrimary,
          title: Text(
            'Start a new Work Order',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          elevation: 0,
        ),
        backgroundColor: colorScheme.surface,
        body: SafeArea(
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
        ),
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
      final workOrderId = Uuid().v4();

      List<FeaturedMediaModel> featuredImages = [];
      List<XFile> pickedImages = [];
      if (workorder.featuredMedia!.isNotEmpty) {
        for (var i = 0; i < workorder.featuredMedia!.length; i++) {
          final imagePath = workorder.featuredMedia![i].url;
          if (imagePath!.startsWith('http')) {
            featuredImages = workorder.featuredMedia!;
          } else {
            pickedImages.add(XFile(workorder.featuredMedia![i].url!));
          }
        }
      }
      // Show progress dialog
      showLoadingDialog(context);
      final uploadResult = await uploadImagesToCloudinary(
        context,
        workOrderId,
        pickedImages,
      );

      uploadResult.fold(
        (ifLeft) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            //Navigator.of(context).pop();
          }
          debugPrint(ifLeft);
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

      final author =
          AuthorModel.empty().copyWith(
            uid: createdBy,
            name: user.fullName,
            avatar: user.profileImage,
          );

      workorder = workorder.copyWith(
        createdBy: createdBy,
        uid: workOrderId,
        featuredMedia: featuredImages,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        status: 'DRAFT',
        workOrderType: workorder.workOrderType ?? '',
        author: author,
      );

      // Save via FirebaseWorkOrderService
      final result = await sl<FirebaseWorkOrderService>().createWorkOrder(
        workorder,
      );

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
          debugPrint(l);
          dismissLoadingDialog(context);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          if (!mounted) return;
          context.read<WorkOrderBloc>().add(AddWorkOrder(workorder));
          dismissLoadingDialog(context);
          AppToast.info(context, 'Work Order created successfully!');
          Navigator.pop(context); //
        },
      );
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
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text("✅ Images uploaded successfully!")),
      //   );
      // }

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
