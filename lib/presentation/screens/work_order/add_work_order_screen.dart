import 'dart:io';

import 'package:dartz/dartz.dart' as dartz;
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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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
          pickedImages.add(XFile(workorder.featuredMedia![i].url!));
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
        workOrderId,
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

      final author = AuthorModel.empty().copyWith(
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
        workOrderType: '',
        author: author,
      );
      // Save via FirebaseWorkOrderService
      final result = await sl<FirebaseWorkOrderService>().createWorkOrder(
        workorder,
      );

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
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
          context.read<WorkOrderBloc>().add(AddWorkOrder(workorder));
          Navigator.pop(context);
          Navigator.pop(context, true);
          AppToast.info(context, 'Work Order created successfully!');
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
}
