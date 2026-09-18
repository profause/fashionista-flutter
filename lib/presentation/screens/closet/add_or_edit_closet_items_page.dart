import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_event.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_category_autocomplete_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dartz/dartz.dart' as dartz;
import 'package:uuid/uuid.dart';
// ignore: implementation_imports
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

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
  late final List<Color> _selectedColors = [];
  late bool isEdit = false;

  @override

  void initState() {
    super.initState();
    isEdit = widget.closetItemModel != null;
    userBloc = context.read<UserBloc>();
    _descriptionController = TextEditingController();
    _descriptionController.text = widget.closetItemModel?.description ?? '';
    _brandController = TextEditingController();
    _brandController.text = widget.closetItemModel?.brand ?? '';
    _categoryController = TextEditingController();
    _categoryController.text = widget.closetItemModel?.category ?? '';
    widget.closetItemModel?.colors?.forEach((color) {
      _selectedColors.add(Color(color));
    });

    if (isEdit) {
      widget.closetItemModel?.featuredMedia.forEach((media) {
        previewImages.add(media.url!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        backgroundColor: context.canvasBackground,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: context.hairline.withValues(alpha: 0.6),
          ),
        ),
        title: Text(
          'Add Item',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: context.onCanvasText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _saveClosetItem(
                  widget.closetItemModel ?? ClosetItemModel.empty(),
                );
                //Navigator.of(context).pop();
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.accent,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 96,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLength: 50,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 15,
                            color: context.onCanvasText,
                          ),
                          decoration: InputDecoration(
                            hintText: hints[random.nextInt(hints.length)],
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: context.placeholderText,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if ((value ?? "").isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _descriptionController,
                        builder: (context, value, _) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${value.text.length}/50',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.placeholderText,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClosetItemCategoryAutocompleteFormFieldWidget(
                    controller: _categoryController,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          style: TextStyle(
                            fontSize: 15,
                            color: context.onCanvasText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'What brand is it?',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: context.placeholderText,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CustomPaint(
                        painter: _DashedBorderPainter(context.hairline),
                        child: Container(
                          width: double.infinity,
                          height: 126,
                          decoration: BoxDecoration(
                            color: context.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.canvasBackground,
                                  border: Border.all(color: context.hairline),
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 20,
                                  color: context.secondaryLabel,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload an image of the item',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.onCanvasText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PNG, JPG up to 10MB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.placeholderText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (previewImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 84,
                        width: double.infinity,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: previewImages.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final image = previewImages[index];
                            return Container(
                              width: 84,
                              height: 84,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: context.cardSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.hairline),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: isEdit
                                        ? CachedNetworkImage(
                                            imageUrl: image.trim(),
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                  child: SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget: (context, url, error) {
                                              return const CustomColoredBanner(
                                                text: '',
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(image),
                                            fit: BoxFit.cover,
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
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick color(s) for this item',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.onCanvasText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final color in _selectedColors)
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  border: Border.all(color: context.hairline),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedColors.remove(color),
                                  );
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
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        GestureDetector(
                          onTap: () => _showColorPickerDialog(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.cardSurface,
                              border: Border.all(color: context.hairline),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: context.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _saveClosetItem(ClosetItemModel closetItemModel) async {
    try {
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      //_buttonLoadingStateCubit.setLoading(true);
      final description = _descriptionController.text.trim();
      final brand = _brandController.text.trim();
      final category = _categoryController.text.trim();
      final closeItemId = isEdit ? closetItemModel.uid : Uuid().v4();
      List<FeaturedMediaModel> featuredImages = closetItemModel.featuredMedia;
      List<int> colors = _selectedColors.map((color) => color.toARGB32()).toList();
      final bool isFavourite = closetItemModel.isFavourite ?? false;
      // Show progress dialog
      showLoadingDialog(context);

      //if (isEdit) {
      final uploadResult = await uploadImagesToCloudinary(
        context,
        closeItemId!,
      );

      uploadResult.fold(
        (ifLeft) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            dismissLoadingDialog(context);
          }
          debugPrint(ifLeft);
        },
        (ifRight) {
          //_buttonLoadingStateCubit.setLoading(false);
          featuredImages = ifRight;
        },
      );
      //}
      final closetItem = ClosetItemModel.empty().copyWith(
        uid: closeItemId,
        createdBy: createdBy,
        description: description,
        createdAt:
            closetItemModel.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        category: category,
        brand: brand,
        featuredMedia: featuredImages,
        isFavourite: isFavourite,
        colors: colors,
      );

      final result = isEdit
          ? await sl<FirebaseClosetService>().updateClosetItem(closetItem)
          : await sl<FirebaseClosetService>().addClosetItem(closetItem);

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            dismissLoadingDialog(context);
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

          context.read<ClosetItemBloc>().add(
            const LoadClosetItemsCacheFirstThenNetwork(''),
          );

          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('✅ Item saved successfully!')));
          dismissLoadingDialog(context);
          if (!isEdit) {
            context.pop();
          }
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

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("✅ Images uploaded successfully!")),
      // );

      return dartz.Right(mergedList);
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
    }
  }

  Future<dartz.Either<String, List<FeaturedMediaModel>>>
  uploadImagesToCloudinary(BuildContext context, String closetItemId) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');

    setState(() => isUploading = true);

    CloudinaryConfig config = CloudinaryConfig.fromUri(
      appConfig.get('cloudinary_url'),
    );
    final closetItemImagesFolder = appConfig.get(
      'cloudinary_closet_item_images_folder',
    );
    final baseFolder = appConfig.get('cloudinary_base_folder');

    final cloudinary = Cloudinary.fromConfiguration(config);

    final uploadTasks = <Future<FeaturedMediaModel>>[];
    final aspects = <double?>[];

    // Step 1: Collect aspect ratios + prepare upload tasks
    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];

      final bytes = await File(image).readAsBytes();
      final base64Image = base64Encode(bytes);

      // get aspect ratio
      final aspect = 1 / 1; //await getImageAspectRatio(image);
      aspects.add(aspect);

      final fileName = "${closetItemId}_$i.jpg";
      final publicId = "${closetItemId}_$i";

      final transformation = Transformation()
          .resize(Resize.auto().width(360).aspectRatio(aspect))
          .addTransformation('q_60');
      // Define upload task returning a non-null String
      final uploadTask = (() async {
        final uploadResult = await cloudinary.uploader().upload(
          'data:image/jpeg;base64,$base64Image',
          params: UploadParams(
            filename: fileName,
            publicId: publicId,
            useFilename: true,
            folder: '$baseFolder/$closetItemImagesFolder',
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
            (cloudinary.image('$baseFolder/$closetItemImagesFolder/$fileName')
                  ..transformation(
                    Transformation().addTransformation('q_auto:eco')
                      ..resize(Resize.auto().width(240).aspectRatio(aspect)),
                  ))
                .toString();
        final featuredMedia = FeaturedMediaModel().copyWith(
          url: url,
          type: "image",
          aspectRatio: aspect,
          thumbnailUrl: thumbnailUrl,
          uid: '$baseFolder/$closetItemImagesFolder/$publicId',
        );
        return featuredMedia; // ✅ Non-null String
      })();

      uploadTasks.add(uploadTask);
    }
    try {
      // Wait for all uploads to finish
      final featuredMedia = await Future.wait(uploadTasks); // List<String>
      final mergedList = featuredMedia;

      setState(() {
        isUploading = false;
      });

      final ctx = context;
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text("✅ Images uploaded successfully!")),
        );
      }

      return dartz.Right(mergedList);
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
    }
  }

  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = Colors.blue;

        return AlertDialog(
          title: const Text("Pick a color"),
          content: SingleChildScrollView(
            child: ColorPicker(
              colorPickerWidth: 300,
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.7,
              displayThumbColor: true,
              pickerAreaBorderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () {
                setState(() {
                  if (!_selectedColors.contains(tempColor)) {
                    _selectedColors.add(tempColor);
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

  // ValueChanged<Color> callback
  void changeColor(Color color) {
    setState(() {
      if (!_selectedColors.contains(color)) {
        _selectedColors.add(color);
      }
    });
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const dash = 6.0;
    const gap = 4.0;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;

    var distance = 0.0;
    while (distance < metric.length) {
      final start = distance;
      final end = (distance + dash).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(start, end), paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
