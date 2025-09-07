import 'dart:io';
import 'dart:math';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_category_autocomplete_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dartz/dartz.dart' as dartz;
import 'package:uuid/uuid.dart';

List<String> hints = [
  "Give this piece a chic tagline (max 50)",
  "Define its fashion vibe in a line…",
  "Style note: describe the essence ✨",
  "Your item's fashion statement…",
];

class AddOrEditClosetItemsPage extends StatefulWidget {
  final ClosetItemModel? closetItemModel;
  const AddOrEditClosetItemsPage({super.key, this.closetItemModel});

  @override
  State<AddOrEditClosetItemsPage> createState() =>
      _AddOrEditClosetItemsPageState();
}

class _AddOrEditClosetItemsPageState extends State<AddOrEditClosetItemsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _brandController;
  late TextEditingController _categoryController;

  final ImagePicker picker = ImagePicker();
  List<String> pickedImages = [];
  List<double> uploadProgress = [];
  List<String> uploadedUrls = [];
  List<String> previewImages = [];
  bool isUploading = false;

  late UserBloc userBloc;

  @override
  void initState() {
    super.initState();
    userBloc = context.read<UserBloc>();
    _descriptionController = TextEditingController();
    _descriptionController.text = widget.closetItemModel?.description ?? '';
    _brandController = TextEditingController();
    _brandController.text = widget.closetItemModel?.brand ?? '';
    _categoryController = TextEditingController();
    _categoryController.text = widget.closetItemModel?.category ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final random = Random();
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Add item to your closet',
          style: textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CustomIconButtonRounded(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _saveClosetItem();
                  //Navigator.of(context).pop();
                }
              },
              iconData: Icons.check,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextInputFieldWidget(
                  autofocus: true,
                  controller: _descriptionController,
                  hint: hints[random.nextInt(hints.length)],
                  minLines: 1,
                  maxLength: 50,
                  validator: (value) {
                    if ((value ?? "").isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                ClosetItemCategoryAutocompleteFormFieldWidget(
                  controller: _categoryController,
                ),
                const SizedBox(height: 8),
                CustomTextInputFieldWidget(
                  autofocus: true,
                  controller: _brandController,
                  hint: 'What brand is it?',
                  minLines: 1,
                  maxLength: 50,
                  validator: (value) {
                    if ((value ?? "").isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text('Upload an image of the item', style: textTheme.bodyLarge),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomIconButtonRounded(
                      size: 24,
                      onPressed: () {
                        //_chooseImageSource(context);
                        _showImageSourceDialog();
                      },
                      iconData: Icons.add_photo_alternate_outlined,
                    ),
                    const SizedBox(width: 8),
                    if (previewImages.isNotEmpty)
                      Expanded(
                        child: SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8),
                            itemCount: previewImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final image = previewImages[index];
                              return Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1 / 1,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(image),
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
                                        setState(() {
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
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveClosetItem() async {
    try {
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      //_buttonLoadingStateCubit.setLoading(true);
      final description = _descriptionController.text.trim();
      final brand = _brandController.text.trim();
      final category = _categoryController.text.trim();
      final closeItemId = Uuid().v4();
      List<FeaturedMediaModel> featuredImages = [];

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uploadResult = await uploadImages(context, closeItemId);

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

      final closetItem = ClosetItemModel.empty().copyWith(
        uid: closeItemId,
        createdBy: createdBy,
        description: description,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        category: category,
        brand: brand,
        featureMedia: featuredImages,
      );

      final result = await sl<FirebaseClosetService>().addClosetItem(
        closetItem,
      );

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            Navigator.of(context).pop();
          }
          setState(() {
            isUploading = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          // _buttonLoadingStateCubit.setLoading(false);
          setState(() {
            isUploading = false;
          });
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.pop(context, true);
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

  XFile? _imageFile;
  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choose Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile == null) {
        // User canceled → just close the dialog if it's still open
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }

      setState(() {
        _imageFile = pickedFile;
      });

      if (mounted) {
        // Dismiss the dialog manually (only when successful)
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _cropImage();
    } catch (e) {
      _imageFile = null;
      // Optionally show an error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
      }
    }
  }

  Future<void> _cropImage() async {
    try {
      final colorScheme = Theme.of(context).colorScheme;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _imageFile!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 40,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: colorScheme.surface,
            toolbarWidgetColor: colorScheme.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );

      if (croppedFile == null) {
        // User cancelled → just return without uploading
        _imageFile = null;
        return;
      }

      if (mounted) {
        setState(() {
          previewImages.add(croppedFile.path);
          pickedImages.add(croppedFile.path);
        });
      }

      //await _uploadImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to crop image: $e")));
      }
    }
  }

  Future<dartz.Either<String, List<FeaturedMediaModel>>> uploadImages(
    BuildContext context,
    String closetItemId,
  ) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');

    setState(() => isUploading = true);

    final storage = FirebaseStorage.instance;
    final uploadTasks = <Future<String>>[];
    final aspects = <double?>[];

    // Step 1: Collect aspect ratios + prepare upload tasks
    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];

      // get aspect ratio
      final aspect = 1 / 1; //await getImageAspectRatio(image);
      aspects.add(aspect);

      // prepare upload
      uploadTasks.add(() async {
        final fileName = "${closetItemId}_$i.jpg";
        //DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref().child(
          "closet_item_images/${userBloc.state.uid}/$fileName.jpg",
        );

        final uploadTask = ref.putFile(File(image));
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

      setState(() {
        uploadedUrls = urls;
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Images uploaded successfully!")),
      );

      return dartz.Right(mergedList);
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _brandController.dispose();
    _categoryController.dispose();

    previewImages.clear();
    pickedImages.clear();
    uploadedUrls.clear();
    _imageFile = null;
    super.dispose();
  }
}
