import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase_designers_service.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class BannerImageWidget extends StatefulWidget {
  final String uid;
  final ValueNotifier<String> url;
  final bool? isEditable;
  final double? height;
  

  const BannerImageWidget({
    super.key,
    required this.uid,
    required this.url,
    this.isEditable = true,
    this.height = 150,
  });

  @override
  State<BannerImageWidget> createState() => _BannerImageWidgetState();
}

class _BannerImageWidgetState extends State<BannerImageWidget> {
  final ImagePicker picker = ImagePicker();
  double uploadProgress = 0.0;
  String uploadedUrl = '';

  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<String>(
      valueListenable: widget.url,
      builder: (_, currentUrl, __) {
        return SizedBox(
          width: double.infinity,// make it stretch
          height: widget.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: CachedNetworkImage(
                    imageUrl: currentUrl,
                    fit: BoxFit.cover,
                    height: widget.height,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
              if (widget.isEditable!) ...[
                Positioned(
                  right: 16,
                  bottom: 8,
                  child: CustomIconButtonRounded(
                    iconData: Icons.add_photo_alternate,
                    size: 20,
                    onPressed: () async {
                      await _pickImage(widget.uid);
                    },
                  ),
                ),
                if (_isUploading) ...[
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      strokeAlign: 0,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  XFile? _imageFile;
  CroppedFile? _croppedFile;
  Future<void> _pickImage(String uid) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      if (pickedFile != null) {
        _imageFile = pickedFile;
      }
    });
    // if (mounted) {
    //   // Dismiss the dialog manually
    //   Navigator.of(context, rootNavigator: true).pop();
    // }
    if (_imageFile == null) return;
    _cropImage(uid);
  }

  Future<void> _cropImage(String uid) async {
    final colorScheme = Theme.of(context).colorScheme;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _imageFile!.path,
      aspectRatio: CropAspectRatio(ratioX: 3.0, ratioY: 1.0),
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
            //CropAspectRatioPreset.original,
            //CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPresetCustom(),
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioPresets: [
            //CropAspectRatioPreset.original,
            //CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPresetCustom(),
          ],
        ),
      ],
    );

    setState(() {
      _croppedFile = croppedFile ?? _croppedFile;
    });

    _uploadImage(uid);
  }

  Future<void> _uploadImage(String uid) async {
    if (_croppedFile != null) {
      setState(() {
        _isUploading = true;
      });
      final result = await sl<FirebaseDesignersService>().uploadBannerImage(
        uid,
        _croppedFile!,
      );

      result.fold(
        (error) {
          debugPrint('Error: $error');
          _clearImageFile();
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        },
        (url) {
          UserBloc userBloc = context.read<UserBloc>();
          User user = userBloc.state;
          user = user.copyWith(bannerImage: url);
          userBloc.add(UpdateUser(user));

          widget.url.value = url;

          debugPrint('Uploaded! Image URL: $url');
          _clearImageFile();
          setState(() {
            _isUploading = false;
          });
        },
      );
    }
  }

  void _clearImageFile() {
    setState(() {
      _imageFile = null;
      _croppedFile = null;
    });
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (3, 1);

  @override
  String get name => '3x1 (customized)';
}
