import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/designers/designer_service_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/services/firebase/firebase_designer_services_service.dart';
import 'package:fashionista/presentation/screens/designers/widgets/designer_service_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Lists the services a designer offers, with a bottom sheet to add or edit.
class DesignerServicesScreen extends StatefulWidget {
  /// The designer whose services are shown. Defaults to the signed-in user.
  final String? designerId;

  const DesignerServicesScreen({super.key, this.designerId});

  @override
  State<DesignerServicesScreen> createState() => _DesignerServicesScreenState();
}

class _DesignerServicesScreenState extends State<DesignerServicesScreen> {
  late final String _designerId;
  List<DesignerServiceModel> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _designerId =
        widget.designerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);

    final result = await sl<FirebaseDesignerServicesService>()
        .findDesignerServices(_designerId);

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() => _loading = false);
        AppToast.error(context, error);
      },
      (services) {
        setState(() {
          _loading = false;
          _services = services;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: context.canvasBackground,
        foregroundColor: context.onCanvasText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Services',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.onCanvasText,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CustomIconButtonRounded(
              onPressed: () async {
                _showServiceBottomSheet();
              },
              iconData: Icons.add,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: ColoredBox(color: context.hairline),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_services.isEmpty) {
      return const PageEmptyWidget(
        title: 'No services yet',
        subtitle: 'Add the services you offer so clients can book you.',
        icon: Icons.design_services_outlined,
        iconSize: 56,
        fontSize: 16,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _services.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final service = _services[index];
        return DesignerServiceCardWidget(
          key: ValueKey(service.uid),
          service: service,
          onTap: () => _showServiceBottomSheet(existing: service),
          onEdit: () => _showServiceBottomSheet(existing: service),
          onDelete: () => _deleteService(service),
        );
      },
    );
  }

  /// Opens the add/edit bottom sheet. Pass [existing] to edit a service.
  Future<void> _showServiceBottomSheet({DesignerServiceModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DesignerServiceFormSheet(
        designerId: _designerId,
        existing: existing,
      ),
    );

    if (!mounted || saved != true) return;

    AppToast.success(
      context,
      existing == null ? 'Service added' : 'Service updated',
    );
    _loadServices();
  }

  Future<void> _deleteService(DesignerServiceModel service) async {
    final uid = service.uid;
    if (uid == null) return;

    final canDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (canDelete != true) return;

    final result = await sl<FirebaseDesignerServicesService>()
        .deleteDesignerService(uid);

    if (!mounted) return;

    result.fold(
      (error) => AppToast.error(
        context,
        error?.toString() ?? 'Failed to delete service',
      ),
      (_) {
        setState(() {
          _services = _services.where((s) => s.uid != uid).toList();
        });
        AppToast.success(context, 'Service deleted');
      },
    );
  }
}

/// Add/edit form for a designer service, rendered inside a modal bottom sheet.
///
/// Owns its [TextEditingController]s so they are disposed only once the sheet
/// has been fully removed from the tree (avoiding "used after being disposed"
/// assertions during the sheet's exit animation).
class _DesignerServiceFormSheet extends StatefulWidget {
  final String designerId;
  final DesignerServiceModel? existing;

  const _DesignerServiceFormSheet({required this.designerId, this.existing});

  @override
  State<_DesignerServiceFormSheet> createState() =>
      _DesignerServiceFormSheetState();
}

class _DesignerServiceFormSheetState extends State<_DesignerServiceFormSheet> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  /// Tags kept in sync with the [TagInputField].
  late List<String> _tags;

  /// Images already stored on the service.
  late List<FeaturedMediaModel> _savedImages;

  /// Images picked locally, previewed and uploaded only when the form is saved.
  final List<XFile> _pickedImages = [];

  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _priceController = TextEditingController(
      text: existing == null || existing.price == 0
          ? ''
          : existing.price.toStringAsFixed(2),
    );
    _tags = List<String>.of(existing?.tagList ?? const <String>[]);
    _savedImages = List<FeaturedMediaModel>.of(
      existing?.featuredImages ?? const <FeaturedMediaModel>[],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim().replaceAll(',', '');
    final price = priceText.isEmpty ? 0.0 : double.tryParse(priceText);

    if (name.isEmpty) {
      AppToast.info(context, 'Enter a service name');
      return;
    }
    if (price == null || price < 0) {
      AppToast.info(context, 'Enter a valid price');
      return;
    }

    setState(() => _isSaving = true);

    // Upload the images picked in this session only now that the user saved.
    // Images already stored on the service are kept as they are.
    var featuredImages = List<FeaturedMediaModel>.of(_savedImages);
    if (_pickedImages.isNotEmpty) {
      final uploadResult = await _uploadImagesToCloudinary(_pickedImages);
      if (!mounted) return;

      if (uploadResult.isLeft()) {
        setState(() => _isSaving = false);
        AppToast.error(
          context,
          uploadResult.fold((error) => error, (_) => 'Image upload failed'),
        );
        return;
      }

      featuredImages = <FeaturedMediaModel>[
        ...featuredImages,
        ...uploadResult.getOrElse(() => const <FeaturedMediaModel>[]),
      ];
    }

    final service = (widget.existing ?? DesignerServiceModel.empty()).copyWith(
      uid: widget.existing?.uid ?? Uuid().v4(),
      createdBy: widget.designerId,
      name: name,
      description: _descriptionController.text.trim(),
      tags: _tags.join(','),
      price: price,
      featuredImages: featuredImages,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final result = _isEdit
        ? await sl<FirebaseDesignerServicesService>().updateDesignerService(
            service,
          )
        : await sl<FirebaseDesignerServicesService>().addDesignerService(
            service,
          );

    if (!mounted) return;

    result.fold((error) {
      setState(() => _isSaving = false);
      AppToast.error(context, error?.toString() ?? 'Something went wrong');
    }, (_) => Navigator.of(context).pop(true));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: context.softBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Service' : 'Add Service',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.onCanvasText,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: context.secondaryLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildField(
              label: 'Service name',
              controller: _nameController,
              hint: 'e.g. Custom bridal gown',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),

            _buildField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'Describe what this service includes...',
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),

            _buildTagsField(),
            const SizedBox(height: 14),

            _buildField(
              label: 'Price',
              controller: _priceController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 20),

            _buildImagesSection(context),
            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Add service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.onCanvasText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: TextStyle(fontSize: 14, color: context.onCanvasText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: context.placeholderText),
            filled: true,
            fillColor: context.canvasBackground,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.onCanvasText,
          ),
        ),
        const SizedBox(height: 6),
        TagInputField(
          label: '',
          hint: 'Type and press Enter, Space or Comma to add a tag',
          valueIn: _tags,
          valueOut: (values) => _tags = values,
        ),
      ],
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    final total = _savedImages.length + _pickedImages.length;
    final hint = total == 0
        ? 'The first image becomes the cover'
        : _pickedImages.isEmpty
        ? '$total · first is the cover'
        : '$total · ${_pickedImages.length} uploaded on save';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.onCanvasText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: context.mutedText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: total + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == total) {
                return _buildAddImageTile(context);
              }
              if (index < _savedImages.length) {
                return _buildSavedImageThumb(context, index);
              }
              return _buildPickedImageThumb(
                context,
                index - _savedImages.length,
                isCover: index == 0,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedImageThumb(BuildContext context, int index) {
    final media = _savedImages[index];
    final thumbnail = media.thumbnailUrl?.trim() ?? '';

    return _buildImageThumb(
      context,
      isCover: index == 0,
      imageUrl: thumbnail.isNotEmpty ? thumbnail : (media.url ?? ''),
      onRemove: () => setState(
        () =>
            _savedImages = List<FeaturedMediaModel>.of(_savedImages)
              ..removeAt(index),
      ),
    );
  }

  Widget _buildPickedImageThumb(
    BuildContext context,
    int index, {
    required bool isCover,
  }) {
    return _buildImageThumb(
      context,
      isCover: isCover,
      file: File(_pickedImages[index].path),
      pendingUpload: true,
      onRemove: () => setState(() => _pickedImages.removeAt(index)),
    );
  }

  Widget _buildAddImageTile(BuildContext context) {
    return InkWell(
      onTap: _isSaving ? null : _pickImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: context.canvasBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.hairline),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 20,
                color: context.accent,
              ),
              const SizedBox(height: 4),
              Text(
                'Add images',
                style: TextStyle(fontSize: 10.5, color: context.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumb(
    BuildContext context, {
    required bool isCover,
    required VoidCallback onRemove,
    String? imageUrl,
    File? file,
    bool pendingUpload = false,
  }) {
    final url = imageUrl?.trim() ?? '';
    final hasImage = file != null || url.isNotEmpty;

    return SizedBox(
      width: 88,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: context.canvasBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCover ? context.accent : context.hairline,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: !hasImage
                  ? Icon(Icons.image_outlined, color: context.mutedText)
                  : file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: context.canvasBackground),
                      errorWidget: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: context.mutedText,
                      ),
                    ),
            ),
          ),
          if (isCover)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (pendingUpload)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: _isSaving ? null : onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Adds images to the form. They are previewed locally from disk and only
  /// uploaded to Cloudinary when the form is saved.
  Future<void> _pickImages() async {
    final List<XFile> files;
    try {
      files = await _picker.pickMultiImage();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not open the gallery');
      return;
    }

    if (files.isEmpty || !mounted) return;

    setState(() => _pickedImages.addAll(files));
  }

  /// Uploads [files] to Cloudinary and returns the resulting media models.
  ///
  /// Called from [_save] so the images are only pushed when the form is
  /// submitted. Follows the same folder/transformation recipe used when adding
  /// a design collection, so service images are stored and delivered
  /// identically.
  Future<dartz.Either<String, List<FeaturedMediaModel>>>
  _uploadImagesToCloudinary(List<XFile> files) async {
    final cloudinaryUrl = appConfig.get('cloudinary_url')?.toString() ?? '';
    if (cloudinaryUrl.isEmpty) {
      return const dartz.Left('Image service is not configured');
    }

    final baseFolder =
        appConfig.get('cloudinary_base_folder')?.toString() ?? '';
    final serviceMediaFolder =
        (appConfig.get('cloudinary_designer_service_images_folder')
            as String?) ??
        'designer_service_images';
    final folder = baseFolder.isEmpty
        ? serviceMediaFolder
        : '$baseFolder/$serviceMediaFolder';

    final cloudinary = Cloudinary.fromConfiguration(
      CloudinaryConfig.fromUri(cloudinaryUrl),
    );

    final uploaded = <FeaturedMediaModel>[];

    try {
      for (final image in files) {
        final aspect = await getImageAspectRatio(image) ?? 16 / 9;
        final publicId = Uuid().v4();
        final fileName = '$publicId.jpg';

        final transformation = Transformation()
            .resize(Resize.auto().width(480).aspectRatio(aspect))
            .addTransformation('q_auto:best');

        final uploadResult = await cloudinary.uploader().upload(
          File(image.path),
          params: UploadParams(
            filename: fileName,
            publicId: publicId,
            useFilename: true,
            folder: folder,
            uploadPreset: 'ml_default',
            type: 'image/jpeg',
            transformation: transformation,
          ),
        );

        if (uploadResult == null) {
          throw Exception('Upload failed — no response from Cloudinary');
        }
        if (uploadResult.error != null) {
          throw Exception(uploadResult.error!.message);
        }

        final url = uploadResult.data?.secureUrl;
        if (url == null) {
          throw Exception('Upload failed — no URL returned');
        }

        final thumbnailUrl =
            (cloudinary.image('$folder/$fileName')..transformation(
                  Transformation().addTransformation('q_auto:eco')
                    ..resize(Resize.auto().width(360).aspectRatio(aspect)),
                ))
                .toString();

        uploaded.add(
          FeaturedMediaModel(
            url: url,
            uid: '$folder/$publicId',
            type: 'image',
            aspectRatio: aspect,
            thumbnailUrl: thumbnailUrl,
          ),
        );
      }

      return dartz.Right(uploaded);
    } catch (e) {
      // Nothing is persisted on failure: the local picks stay in the form so
      // the user can fix the problem and save again.
      return dartz.Left(e.toString());
    }
  }
}
