import 'dart:io';

import 'package:dartz/dartz.dart' as dartz;
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_design_collection_service.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddDesignCollectionScreen extends StatefulWidget {
  final DesignCollectionModel? designCollection;

  const AddDesignCollectionScreen({super.key, this.designCollection});

  @override
  State<AddDesignCollectionScreen> createState() =>
      _AddDesignCollectionScreenState();
}

class _AddDesignCollectionScreenState extends State<AddDesignCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _visibilityController;
  late TextEditingController _creditsController;
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;

  List<XFile> previewImages = [];
  final ImagePicker picker = ImagePicker();
  List<XFile> pickedImages = [];
  List<double> uploadProgress = [];
  List<String> uploadedUrls = [];

  bool isUploading = false;

  @override
  void initState() {
    _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
    //_authProviderCubit = context.read<AuthProviderCubit>();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();
    _visibilityController = TextEditingController();
    _creditsController = TextEditingController();

    if (widget.designCollection == null) {
      setState(() {
        //widget.designCollection = DesignCollectionModel.empty();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Add Design Collection',
          style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (previewImages.isNotEmpty)
                        SizedBox(
                          height: 220,
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
                                    aspectRatio: 3 / 4,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            children: [
                              if (isUploading) ...[
                                CircularProgressIndicator(strokeWidth: 4),
                              ],
                              CustomIconButtonRounded(
                                iconData: Icons.add_photo_alternate,
                                onPressed: () {
                                  if (isUploading) return;
                                  pickImages(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
                Card(
                  color: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileInfoTextFieldWidget(
                          label: 'Title',
                          controller: _titleController,
                          hint: 'Enter a title for your collection',
                          validator: (value) {
                            if (!RegExp(
                              r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                            ).hasMatch(value ?? "")) {
                              return 'Please enter a valid name';
                            }
                            return null;
                          },
                        ),
                        Divider(
                          height: 16,
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                        ProfileInfoTextFieldWidget(
                          label: 'Description',
                          controller: _descriptionController,
                          hint: 'Enter a your collection',
                          validator: (value) {
                            if (!RegExp(
                              r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                            ).hasMatch(value ?? "")) {
                              return 'Please enter a valid description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Card(
                  color: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomIconRounded(icon: Icons.tag),
                            const SizedBox(width: 8),
                            Text("Featured Tags"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TagInputField(
                          label: '',
                          hint:
                              'Type and press Enter, Space or Comma to add a tag',
                          valueIn: [],
                          valueOut: (value) =>
                              _tagsController.text = value.join('|'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Card(
                  color: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomChipFormFieldWidget(
                          initialValue: 'public',
                          label: 'Visibility',
                          items: ['public', 'private'],
                          onChanged: (value) {
                            _visibilityController.text = value;
                          },
                        ),
                        Divider(
                          height: 16,
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            CustomIconRounded(icon: Icons.info_outline),
                            const SizedBox(width: 8),
                            Text("Credits"),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TagInputField(
                          label: '',
                          hint:
                              'Type and press Enter, Space or Comma to add a tag',
                          valueIn: [],
                          valueOut: (value) =>
                              _creditsController.text = value.join('|'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                    child: Hero(
                      tag: 'add-design-collection-button',
                      child: AnimatedPrimaryButton(
                        text: "Save",
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          await _saveDesignCollection(
                            DesignCollectionModel.empty(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDesignCollection(
    DesignCollectionModel designCollection,
  ) async {
    try {
      UserBloc userBloc = context.read<UserBloc>();
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      _buttonLoadingStateCubit.setLoading(true);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final visibility = _visibilityController.text.trim();
      final tags = _tagsController.text.trim();
      final credits = _creditsController.text.trim();
      final designCollectionId = Uuid().v4();

      final uploadResult = await uploadImages(
        context,
        createdBy,
        designCollectionId,
      );

      uploadResult.fold(
        (ifLeft) {
          // _buttonLoadingStateCubit.setLoading(false);
          debugPrint(ifLeft);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
          return;
        },
        (ifRight) {
          //_buttonLoadingStateCubit.setLoading(false);
          setState(() {
            //isUploading = false;
            uploadedUrls = ifRight;
          });
        },
      );

      final author = AuthorModel.empty().copyWith(
        uid: createdBy,
        name: user.fullName,
        avatar: user.profileImage,
      );

      final newDesignCollection = designCollection.copyWith(
        uid: designCollectionId,
        createdBy: createdBy,
        title: title,
        description: description,
        visibility: visibility,
        tags: tags,
        credits: credits,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        author: author,
        featuredImages: uploadedUrls,
      );
      //debugPrint(newDesignCollection.toJson().toString());

      final result = await sl<FirebaseDesignCollectionService>()
          .addDesignCollectionToFirestore(newDesignCollection);

      result.fold(
        (l) {
          _buttonLoadingStateCubit.setLoading(false);
          setState(() {
            isUploading = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          _buttonLoadingStateCubit.setLoading(false);
          setState(() {
            isUploading = false;
          });
          if (!mounted) return;
          //Navigator.pop(context);
          Navigator.pop(context, true);
        },
      );

      //here initiate featured images upload
    } on firebase_auth.FirebaseException catch (e) {
      _buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  Future<void> pickImages(BuildContext context) async {
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      pickedImages = images;
      previewImages = images;
      uploadProgress = List.filled(images.length, 0.0);
      uploadedUrls.clear();
    });

    if (context.mounted) {
      //uploadImages(context);
      //setPreviewImages();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _visibilityController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<dartz.Either<String, List<String>>> uploadImages(
    BuildContext context,
    String designerId,
    designCollectionId,
  ) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');

    setState(() => isUploading = true);

    final storage = FirebaseStorage.instance;
    final uploadTasks = <Future<String>>[];

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      uploadTasks.add(() async {
        final fileName = "${designCollectionId}_$i";

        //DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref().child(
          "design_collection_images/$designerId/$fileName.jpg",
        );

        final uploadTask = ref.putFile(File(image.path));

        // // Track progress
        // uploadTask.snapshotEvents.listen((snapshot) {
        //   final percent = snapshot.bytesTransferred / snapshot.totalBytes;
        //   setState(() {
        //     uploadProgress[i] = percent;
        //   });
        // });

        await uploadTask;
        return await ref.getDownloadURL();
      }());
    }

    try {
      final urls = await Future.wait(uploadTasks);
      setState(() {
        uploadedUrls = urls;
        isUploading = false;
      });

      // Save to Firestore
      // await FirebaseFirestore.instance
      //     .collection("designers")
      //     .doc(widget.designer.uid)
      //     .set({
      //       "featured_images": FieldValue.arrayUnion(urls),
      //     }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Images uploaded successfully!")),
      );
      return dartz.Right(urls);
      //context.read<DesignerBloc>().add(LoadDesigner(widget.designer.uid));
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
    }
  }
}
