import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/core/widgets/autosuggest_tag_input_field.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_usecase.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:fashionista/presentation/widgets/profile_avatar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

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
  late ValueNotifier<String> imageQuality = ValueNotifier('SD');
  final List<String> selectedInterests = [];
  late SettingsBloc _settingsBloc;

  int _currentLength = 0;
  final int _maxLength = 100; // keep in sync with input field

  final ImagePicker picker = ImagePicker();
  List<XFile> pickedImages = [];
  List<double> uploadProgress = [];
  List<XFile> previewImages = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
    _settingsBloc = context.read<SettingsBloc>();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();
    _descriptionController.addListener(() {
      setState(() {
        _currentLength = _descriptionController.text.length;
      });
    });

    imageQuality.value = _settingsBloc.state.imageQuality ?? 'SD';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagsController.dispose();
    previewImages.clear();
    pickedImages.clear();
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
            child: Hero(
              tag: 'add-post',
              child: CustomIconButtonRounded(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _saveTrend();
                    //Navigator.of(context).pop();
                  }
                },
                iconData: Icons.check,
              ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14.0),
                      child: ProfileAvatar(radius: 24),
                    ),
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
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomIconRounded(icon: Icons.tag, size: 20),
                    const SizedBox(width: 8),

                    //Text("Featured Tags"),
                    Expanded(
                      child: AutosuggestTagInputField(
                        hint:
                            'Type and press Enter, Space or Comma to add a tag',
                        valueIn: [],
                        options: selectedInterests,
                        valueOut: (value) =>
                            _tagsController.text = value.join(','),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: .1, thickness: .1),
                const SizedBox(height: 16),
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
                        //const SizedBox(width: 16),
                        // CustomIconButtonRounded(
                        //   onPressed: () {},
                        //   iconData: Icons.video_camera_back,
                        // ),
                        const SizedBox(width: 16),
                        CustomIconButtonRounded(
                          onPressed: () {
                            _pickImage(ImageSource.camera);
                          },
                          iconData: Icons.camera_alt_outlined,
                        ),
                        const SizedBox(width: 16),
                        ValueListenableBuilder(
                          valueListenable: imageQuality,
                          builder: (context, quality, _) {
                            return CustomIconButtonRounded(
                              onPressed: () {
                                if (imageQuality.value == 'SD') {
                                  imageQuality.value = 'HD';
                                } else {
                                  imageQuality.value = 'SD';
                                }
                              },
                              iconData: imageQuality.value == 'SD'
                                  ? Icons.sd_outlined
                                  : Icons.hd_outlined,
                            );
                          },
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
    final images = await picker.pickMultiImage(
      imageQuality: 70,
      limit: 4,
      requestFullMetadata: true,
    );
    if (images.isEmpty) return;

    setState(() {
      pickedImages = images;
      for (var i = 0; i < images.length; i++) {
        previewImages.add(images[i]);
      }
      //images.forEach((i)=>previewImages.add(i));
      uploadProgress = List.filled(images.length, 0.0);
    });

    if (context.mounted) {
      //uploadImages(context);
      //setPreviewImages();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          previewImages.add(pickedFile);
          pickedImages.add(pickedFile);
        });
      }
    } catch (e, st) {
      debugPrint('Error picking image: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _saveTrend() async {
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
      showLoadingDialog(context);
      final uploadResult = await uploadImagesToCloudinary(context, trendId);

      uploadResult.fold(
        (ifLeft) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            dismissLoadingDialog(context);
          }
          //debugPrint(ifLeft);
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
            //Navigator.of(context).pop();
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
          if (mounted) {
            context.read<TrendBloc>().add(AddTrend(trend));
          }
          // _buttonLoadingStateCubit.setLoading(false);
          setState(() {
            isUploading = false;
          });
          if (!mounted) return;
          dismissLoadingDialog(context);
          context.pop();
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

  Future<dartz.Either<String, List<FeaturedMediaModel>>>
  uploadImagesToCloudinary(BuildContext context, String trendId) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');
    setState(() => isUploading = true);
    CloudinaryConfig config = CloudinaryConfig.fromUri(
      appConfig.get('cloudinary_url'),
    );
    final trendMediaFolder = appConfig.get('cloudinary_trend_media_folder');
    final baseFolder = appConfig.get('cloudinary_base_folder');

    final cloudinary = Cloudinary.fromConfiguration(config);
    final aspects = <double?>[];
    final uploadTasks =
        <Future<FeaturedMediaModel>>[]; // explicitly Future<String>

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      final uploadFile = File(image.path);

      // Get aspect ratio
      final aspect = await getImageAspectRatio(image);
      aspects.add(aspect);

      final fileName = "${trendId}_$i.jpg";
      final publicId = "${trendId}_$i";

      final transformation = Transformation()
          .resize(Resize.auto().width(480).aspectRatio(aspect))
          .addTransformation(imageQuality.value == 'SD' ? 'q_60' : 'q_90');
      // Define upload task returning a non-null String
      final uploadTask = (() async {
        final uploadResult = await cloudinary.uploader().upload(
          uploadFile,
          params: UploadParams(
            filename: fileName,
            publicId: publicId,
            useFilename: true,
            folder: '$baseFolder/$trendMediaFolder',
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
            (cloudinary.image('$baseFolder/$trendMediaFolder/$fileName')
                  ..transformation(
                    Transformation().addTransformation('q_auto:eco')
                      ..resize(Resize.auto().width(360).aspectRatio(aspect)),
                  ))
                .toString();
        final featuredMedia = FeaturedMediaModel().copyWith(
          url: url,
          type: "image",
          aspectRatio: aspect,
          thumbnailUrl: thumbnailUrl,
          uid: '$baseFolder/$trendMediaFolder/$publicId',
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Images uploaded successfully!")),
        );
      }

      return dartz.Right(mergedList);
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
    }
  }

  Future<dartz.Either<String, List<FeaturedMediaModel>>> uploadImages(
    BuildContext context,
    String trendId,
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
      final aspect = await getImageAspectRatio(image);
      aspects.add(aspect);

      // prepare upload
      uploadTasks.add(() async {
        final fileName = "${trendId}_$i.jpg";
        final ref = storage.ref().child("trend_media/$fileName");

        final uploadTask = ref.putFile(
          File(image.path),
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=15768000',
          ),
        );
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
        isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Images uploaded successfully!")),
        );
      }

      return dartz.Right(mergedList);
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
    }
  }

  Future<void> _loadUserInterests() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final List<dynamic>? interests = data?['interests'];
      if (interests != null) {
        setState(() {
          selectedInterests.addAll(interests.cast<String>());
        });
      }
    }
    //setState(() => _loadingUserInterests = false);
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
