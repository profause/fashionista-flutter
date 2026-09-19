import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/widgets/grid_thumbnail_widget.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_tag_picker_widget.dart';
import 'package:fashionista/presentation/widgets/custom_autocomplete_form_field_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:uuid/uuid.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

final occasions = [
  {
    "label": "Wedding",
    "icon":
        Icons.favorite, // ❤️ or use wedding rings icon from other icon packs
  },
  {
    "label": "Office",
    "icon": Icons.work_outline, // briefcase
  },
  {
    "label": "Dinner",
    "icon": Icons.restaurant_menu, // 🍽️
  },
  {
    "label": "Party",
    "icon": Icons.celebration, // 🎉
  },
  {
    "label": "Beach",
    "icon": Icons.beach_access, // 🌴
  },
  {
    "label": "Casual",
    "icon": Icons.weekend, // 🛋️
  },
];

final outfitTags = [
  "Summer",
  "Winter",
  "Travel",
  "Casual",
  "Formal",
  "Luxury",
  "Trendy",
  "Streetwear",
  "Vintage",
  "Sporty",
  "Chic",
  "Night Out",
];

class AddOrEditOutfitScreen extends StatefulWidget {
  final OutfitModel? outfitModel;
  const AddOrEditOutfitScreen({super.key, this.outfitModel});

  @override
  State<AddOrEditOutfitScreen> createState() => _AddOrEditOutfitScreenState();
}

class _AddOrEditOutfitScreenState extends State<AddOrEditOutfitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _styleController;
  late TextEditingController _occasionController;
  late TextEditingController _tagsController;
  late List<FeaturedMediaModel> previewImages = [];
  final List<String> imageUrls = [];
  late Uint8List? _thumbnailBytes;

  late UserBloc userBloc;
  //late List<Color> _selectedColors = [];
  late bool isEdit = false;
  List<String> selectedTags = [];

  @override
  void initState() {
    super.initState();
    isEdit = widget.outfitModel!.uid!.isNotEmpty ? true : false;
    userBloc = context.read<UserBloc>();
    _styleController = TextEditingController();
    _styleController.text = widget.outfitModel?.style ?? '';
    _occasionController = TextEditingController();
    _occasionController.text = widget.outfitModel?.occassion ?? '';
    _tagsController = TextEditingController();
    selectedTags = widget.outfitModel?.tags?.split('|') ?? [];
    widget.outfitModel?.closetItems.forEach((item) {
      previewImages.add(item.featuredMedia.first);
      imageUrls.add(item.featuredMedia.first.url ?? "");
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        backgroundColor: context.cardSurface,
        foregroundColor: context.onCanvasText,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, size: 30),
          ),
        ),
        title: Text(
          'Add Outfit To Your Closet',
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.onCanvasText,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: Material(
                  color: context.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        await _saveOutfitItem(
                          widget.outfitModel ?? OutfitModel.empty(),
                        );
                      }
                    },
                    child: const Center(
                      child: Icon(Icons.check, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.hairline),
        ),
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
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GridThumbnailWidget(
                    imageUrls: imageUrls,
                    size: 140,
                    onImageLoaded: (thumbnailBytes) {
                      if (thumbnailBytes != null) {
                        setState(() {
                          _thumbnailBytes = thumbnailBytes;
                        });
                      }
                      //debugPrint("Thumbnail bytes: $thumbnailBytes");
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Field A: Style notes
                _FieldLabel(text: 'Style notes'),
                const SizedBox(height: 6),
                _buildStyleNotesField(),
                const SizedBox(height: 16),
                // Field B: Occasion
                const _FieldLabel(text: 'Occasion'),
                const SizedBox(height: 6),
                Container(
                  height: 50,
                  //padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                    boxShadow: [_softShadow()],
                  ),
                  child: CustomAutocompleteFormFieldWidget(
                    controller: _occasionController,
                    autoCompleteItems: occasions,
                    hintText: 'Describe the occasion...',
                  ),
                ),
                const SizedBox(height: 20),
                // Featured tags header
                Row(
                  children: [
                    Expanded(child: const _FieldLabel(text: 'Featured tags')),
                    Text(
                      'Multi-select',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutfitTagPickerWidget(
                  availableTags: outfitTags,
                  selectedTags: selectedTags,
                  onChanged: (newTags) {
                    setState(() {
                      selectedTags = newTags;
                      _tagsController.text = newTags.join('|');
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleNotesField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
        boxShadow: [_softShadow()],
      ),
      child: TextFormField(
        autofocus: true,
        controller: _styleController,
        minLines: 2,
        maxLines: 4,
        maxLength: 50,
        validator: (value) {
          if ((value ?? "").isEmpty) {
            return 'Describe your style inspiration...';
          }
          return null;
        },
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          counterStyle: TextStyle(fontSize: 11, color: context.placeholderText),
          hintText: 'Describe your style inspiration...',
          hintStyle: TextStyle(fontSize: 14, color: context.placeholderText),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  BoxShadow _softShadow() {
    return BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 3),
    );
  }

  Future<void> _saveOutfitItem(OutfitModel outfit) async {
    try {
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      //_buttonLoadingStateCubit.setLoading(true);
      final style = _styleController.text.trim();
      final occassion = _occasionController.text.trim();
      final tags = _tagsController.text.trim();
      final outfitId = isEdit ? outfit.uid : Uuid().v4();
      final createdAt = isEdit
          ? outfit.createdAt
          : DateTime.now().millisecondsSinceEpoch;

      // Show progress dialog
      showLoadingDialog(context);

      //here lets upload _thumbnailBytes
      if (!isEdit) {
        if (_thumbnailBytes != null) {
          String? thumbnailUrl = await uploadThumbnailToCloudinary(
            context,
            _thumbnailBytes!,
            outfitId!,
          );

          if (thumbnailUrl != null) {
            outfit = outfit.copyWith(thumbnailUrl: thumbnailUrl);
          }
        }
      }

      outfit = outfit.copyWith(
        uid: outfitId,
        style: style,
        occassion: occassion,
        tags: tags,
        createdAt: createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdBy: createdBy,
        isFavourite: false,
      );

      final result = isEdit
          ? await sl<FirebaseClosetService>().updateOutfit(outfit)
          : await sl<FirebaseClosetService>().addOutfit(outfit);

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            dismissLoadingDialog(context);
          }
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (!mounted) return;
          context.read<ClosetOutfitBloc>().add(
            const LoadOutfitsCacheFirstThenNetwork(''),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Outfit saved successfully!')),
          );
          dismissLoadingDialog(context);
          if (mounted) {
            Navigator.pop(context);
          }
          // if (!isEdit) {
          //   context.pop();
          // }
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

  Future<String?> uploadThumbnail(
    BuildContext context,
    Uint8List thumbnailBytes,
    String outfitId,
  ) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        "outfit_thumbnails/${outfitId}_${const Uuid().v4()}.png",
      );

      await storageRef.putData(
        thumbnailBytes,
        SettableMetadata(contentType: "image/png"),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint("Thumbnail upload failed: $e");
      return null;
    }
  }

  Future<String?> uploadThumbnailToCloudinary(
    BuildContext context,
    Uint8List thumbnailBytes,
    String outfitId,
  ) async {
    try {
      CloudinaryConfig config = CloudinaryConfig.fromUri(
        appConfig.get('cloudinary_url'),
      );
      final outfitThumbnailsFolder = appConfig.get(
        'cloudinary_outfit_thumbnails_folder',
      );
      final baseFolder = appConfig.get('cloudinary_base_folder');

      final cloudinary = Cloudinary.fromConfiguration(config);
      final tempId = const Uuid().v4();
      final fileName = "${outfitId}_$tempId.png";
      final publicId = "${outfitId}_$tempId";

      final base64Image = base64Encode(thumbnailBytes);

      final transformation = Transformation()
          .resize(Resize.auto().width(360).aspectRatio(1 / 1))
          .addTransformation('q_60');

      final uploadResult = await cloudinary.uploader().upload(
        'data:image/jpeg;base64,$base64Image',
        params: UploadParams(
          filename: fileName,
          publicId: publicId,
          useFilename: true,
          folder: '$baseFolder/$outfitThumbnailsFolder',
          uploadPreset: 'ml_default',
          type: 'image/png',
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
          (cloudinary.image('$baseFolder/$outfitThumbnailsFolder/$fileName')
                ..transformation(
                  Transformation().addTransformation('q_auto:good')
                    ..resize(Resize.auto().width(250).aspectRatio(1 / 1)),
                ))
              .toString();

      final downloadUrl = thumbnailUrl;
      return downloadUrl;
    } catch (e) {
      debugPrint("Thumbnail upload failed: $e");
      return null;
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

  @override
  void dispose() {
    _styleController.dispose();
    _occasionController.dispose();
    _tagsController.dispose();
    previewImages.clear();
    super.dispose();
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.onCanvasText,
        ),
      ),
    );
  }
}
