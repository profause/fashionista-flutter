import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
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
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
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
  static const int _maxMedia = 4; // matches the picker limit

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
    final textTheme = Theme.of(context).textTheme;

    final random = Random();

    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        backgroundColor: context.canvasBackground,
        foregroundColor: context.onCanvasText,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: context.hairline)),
        title: const AppBarTitle(title: 'Start a trend'),
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
                icon: Icon(Icons.check, color: context.accent, size: 24),
                iconData: Icons.check,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComposerCard(context, textTheme, random),
                const SizedBox(height: 16),
                _buildLookbookSection(context, textTheme),
                const SizedBox(height: 16),
                AutosuggestTagInputField(
                  hint: 'Type and press Enter, Space or Comma',
                  valueIn: [],
                  options: selectedInterests,
                  valueOut: (value) => _tagsController.text = value.join(','),
                ),
                const SizedBox(height: 16),
                _buildMediaToolkit(context, textTheme),
                const SizedBox(height: 16),
                _buildAudienceCard(context, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposerCard(
    BuildContext context,
    TextTheme textTheme,
    Random random,
  ) {
    final bool overLimit = _currentLength >= _maxLength;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileAvatar(radius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  autofocus: true,
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: _maxLength,
                  keyboardType: TextInputType.multiline,
                  style: textTheme.bodyLarge?.copyWith(
                    color: context.onCanvasText,
                    height: 1.4,
                  ),
                  validator: (value) {
                    if ((value ?? "").isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hints[random.nextInt(hints.length)],
                    hintStyle: textTheme.bodyLarge?.copyWith(
                      color: context.placeholderText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Draft',
                style: textTheme.labelSmall?.copyWith(
                  color: context.secondaryLabel,
                ),
              ),
              const Spacer(),
              Text(
                '$_currentLength/$_maxLength',
                style: textTheme.labelSmall?.copyWith(
                  color: overLimit ? context.accent : context.secondaryLabel,
                  fontWeight: overLimit ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLookbookSection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '',
              style: textTheme.labelSmall?.copyWith(
                color: context.secondaryLabel,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: isUploading ? null : () => pickImages(context),
              child: Text(
                'Add media',
                style: textTheme.labelSmall?.copyWith(
                  color: context.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewImages.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == previewImages.length) {
                return _addMediaTile(context, textTheme);
              }
              return _lookbookTile(context, textTheme, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _lookbookTile(BuildContext context, TextTheme textTheme, int index) {
    final image = previewImages[index];
    return SizedBox(
      width: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(image.path), fit: BoxFit.cover),
            // Scrim keeps the label legible over any photo.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: .70),
                        Colors.black.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Look ${index + 1}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _removePreviewImage(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .25),
                    ),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addMediaTile(BuildContext context, TextTheme textTheme) {
    return SizedBox(
      width: 140,
      child: Material(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isUploading ? null : () => pickImages(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.softBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.iconSubstrate,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: context.accent, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add Media',
                  style: textTheme.labelSmall?.copyWith(
                    color: context.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaToolkit(BuildContext context, TextTheme textTheme) {
    final double mediaProgress = (previewImages.length / _maxMedia).clamp(
      0.0,
      1.0,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        children: [
          _toolkitTile(
            context,
            icon: Icons.photo_library_outlined,
            iconColor: context.accent,
            onTap: () {
              if (isUploading) return;
              pickImages(context);
            },
          ),
          const SizedBox(width: 12),
          _toolkitTile(
            context,
            icon: Icons.photo_camera_outlined,
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<String>(
            valueListenable: imageQuality,
            builder: (context, quality, _) {
              return _toolkitTile(
                context,
                icon: quality == 'SD' ? Icons.sd_outlined : Icons.hd_outlined,
                onTap: () => imageQuality.value = quality == 'SD' ? 'HD' : 'SD',
              );
            },
          ),
          const Spacer(),
          Text(
            '${previewImages.length}/$_maxMedia Photos',
            style: textTheme.labelSmall?.copyWith(
              color: context.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: mediaProgress, // media slots filled
              backgroundColor: context.hairline,
              color: context.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolkitTile(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: context.iconSubstrate,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? context.secondaryLabel,
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceCard(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.iconSubstrate,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.public, size: 16, color: context.secondaryLabel),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audience',
                  style: textTheme.labelMedium?.copyWith(
                    color: context.onCanvasText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Public · Anyone can join this trend',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Keeps the reel the user sees in sync with the list that gets uploaded.
  void _removePreviewImage(int index) {
    setState(() {
      if (index < previewImages.length) previewImages.removeAt(index);
      if (index < pickedImages.length) pickedImages.removeAt(index);
      if (index < uploadProgress.length) uploadProgress.removeAt(index);
    });
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
          .addTransformation(imageQuality.value == 'SD' ? 'q_60' : 'q_100');
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
                    Transformation().addTransformation('q_auto:good')
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
