import 'dart:io';
import 'dart:math';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_usecase.dart';
import 'package:fashionista/presentation/screens/designers/widgets/featured_images_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:fashionista/presentation/widgets/profile_avatar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:uuid/uuid.dart';

List<String> hints = [
  "✨ Share your next fashion moment…",
  "👗 What’s trending in your world?",
  "🧵 Stitch your trend into the feed…",
  "🚀 Kick off the next big fashion vibe…",
  "🖋 Describe your style inspiration…",
  "🔥 Drop your hottest fashion trend…",
];

class AddTrendScreen extends StatefulWidget {
  const AddTrendScreen({super.key});

  @override
  State<AddTrendScreen> createState() => _AddTrendScreenState();
}

class _AddTrendScreenState extends State<AddTrendScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;

  int _currentLength = 0;
  final int _maxLength = 100; // keep in sync with input field

  final ImagePicker picker = ImagePicker();
  List<XFile> pickedImages = [];
  List<double> uploadProgress = [];
  List<String> uploadedUrls = [];
  List<XFile> previewImages = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();
    _descriptionController.addListener(() {
      setState(() {
        _currentLength = _descriptionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagsController.dispose();
    previewImages.clear();
    pickedImages.clear();
    uploadedUrls.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final random = Random();

    // progress value for determinate progress indicator
    double progress = _currentLength / _maxLength;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Start a trend',
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
                  await _saveTrend(context);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ProfileAvatar(radius: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextInputFieldWidget(
                        autofocus: true,
                        controller: _descriptionController,
                        hint: hints[random.nextInt(hints.length)],
                        minLines: 2,
                        maxLength: _maxLength,
                        validator: (value) {
                          if ((value ?? "").isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (previewImages.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: previewImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomIconRounded(icon: Icons.tag, size: 20),
                    const SizedBox(width: 8),

                    //Text("Featured Tags"),
                    Expanded(
                      child: TagInputField(
                        hint:
                            'Type and press Enter, Space or Comma to add a tag',
                        valueIn: [],
                        valueOut: (value) =>
                            _tagsController.text = value.join(','),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 16, thickness: 1, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CustomIconButtonRounded(
                          onPressed: () {
                            if (isUploading) return;
                            pickImages(context);
                          },
                          iconData: Icons.image_outlined,
                        ),
                        const SizedBox(width: 16),
                        CustomIconButtonRounded(
                          onPressed: () {},
                          iconData: Icons.video_camera_back,
                        ),
                        const SizedBox(width: 16),
                        CustomIconButtonRounded(
                          onPressed: () {
                            _pickImage(ImageSource.camera);
                          },
                          iconData: Icons.camera_alt_outlined,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$_currentLength/$_maxLength',
                          style: textTheme.bodySmall?.copyWith(
                            color: _currentLength >= _maxLength
                                ? Colors.red
                                : Colors.grey[700],
                            fontWeight: _currentLength >= _maxLength
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress, // determinate value
                            backgroundColor: Colors.grey[300],
                            color: _currentLength >= _maxLength
                                ? Colors.red
                                : colorScheme.primary,
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

  Future<void> pickImages(BuildContext context) async {
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      pickedImages = images;
      for (var i = 0; i < images.length; i++) {
        previewImages.add(images[i]);
      }
      //images.forEach((i)=>previewImages.add(i));
      uploadProgress = List.filled(images.length, 0.0);
      uploadedUrls.clear();
    });

    if (context.mounted) {
      //uploadImages(context);
      //setPreviewImages();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        previewImages.add(pickedFile);
        pickedImages.add(pickedFile);
      }
    });
    if (mounted) {
      // Dismiss the dialog manually
      //Navigator.of(context, rootNavigator: true).pop();
    }
    //_cropImage();
  }

  Future<void> _saveTrend(context) async {
    try {
      UserBloc userBloc = context.read<UserBloc>();
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      //_buttonLoadingStateCubit.setLoading(true);
      final description = _descriptionController.text.trim();
      final tags = _tagsController.text.trim();
      final trendId = Uuid().v4();
      List<FeaturedMediaModel> featuredImages = [];

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final uploadResult = await uploadImages(context, trendId);

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
          setState(() {
            //isUploading = false;
            uploadedUrls = ifRight;
            for (var i = 0; i < uploadedUrls.length; i++) {
              featuredImages.add(
                FeaturedMediaModel(url: uploadedUrls[i], type: 'image'),
              );
            }
          });
        },
      );

      final author = AuthorModel.empty().copyWith(
        uid: createdBy,
        name: user.fullName,
        avatar: user.profileImage,
      );

      final trend = TrendFeedModel.empty().copyWith(
        uid: trendId,
        createdBy: createdBy,
        description: description,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        author: author,
        tags: tags,
        featuredMedia: featuredImages,
      );

      final result = await sl<AddTrendUsecase>().call(trend);

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

  Future<dartz.Either<String, List<String>>> uploadImages(
    BuildContext context,
    trendId,
  ) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');

    setState(() => isUploading = true);

    final storage = FirebaseStorage.instance;
    final uploadTasks = <Future<String>>[];

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      uploadTasks.add(() async {
        final fileName = "${trendId}_$i";

        //DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref().child("trend_images/$fileName.jpg");

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
