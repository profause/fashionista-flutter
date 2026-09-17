import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class WorkOrderFlowPage3 extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  const WorkOrderFlowPage3({super.key, this.onNext, this.onPrev});

  @override
  State<WorkOrderFlowPage3> createState() => _WorkOrderFlowPage3State();
}

class _WorkOrderFlowPage3State extends State<WorkOrderFlowPage3> {
  late TextEditingController _tagsController;
  late WorkOrderModel current;
  final ImagePicker picker = ImagePicker();

  List<XFile> pickedImages = [];
  late ValueNotifier<Set<String>> previewImages;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    current = WorkOrderModel.empty();
    _tagsController = TextEditingController();
    previewImages = ValueNotifier<Set<String>>({});
  }

  @override
  void dispose() {
    _tagsController.dispose();
    previewImages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
                buildWhen: (_, state) => state is WorkOrderPatched,
                builder: (context, state) {
                  // ✅ Pre-fill values when coming back
                  if (state is WorkOrderPatched) current = state.workorder;

                  // Load existing images only once
                  if (current.featuredMedia != null &&
                      current.featuredMedia!.isNotEmpty &&
                      previewImages.value.isEmpty) {
                    previewImages.value = {
                      ...current.featuredMedia!.map((m) => m.url!)
                    };
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoGalleryCard(),
                      const SizedBox(height: 16),
                      _buildTagSection(),
                    ],
                  );
                },
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      color: context.hairline,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.75,
        child: Container(color: context.accent),
      ),
    );
  }

  Widget _buildPhotoGalleryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo Gallery',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.onCanvasText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Upload photos of the work order',
            style: TextStyle(
              fontSize: 13,
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          _buildGalleryCarousel(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.image_outlined,
                  label: 'Add Photo',
                  onTap: () {
                    if (isUploading) return;
                    pickImages();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take Photo',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCarousel() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: previewImages,
      builder: (context, images, _) {
        if (images.isEmpty) {
          return const SizedBox.shrink();
        }
        final list = images.toList();
        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final image = list[index];
              return _buildPhotoCard(image);
            },
          ),
        );
      },
    );
  }

  Widget _buildPhotoCard(String image) {
    return Stack(
      children: [
        Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: context.hairline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                  )
                : Image.file(File(image), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              previewImages.value = {...previewImages.value..remove(image)};
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: context.iconSubstrate,
        foregroundColor: context.onCanvasText,
        side: BorderSide(color: context.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: context.mutedText),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.iconSubstrate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.mutedText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'What are the style inspirations behind this project?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.onCanvasText,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: context.hairline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TagInputField(
            label: null,
            hint: 'Type and press Enter, Space or Comma to add tags.',
            valueIn: current.tags!.isEmpty
                ? []
                : current.tags!.split(',').toList(),
            valueOut: (value) {
              _tagsController.text = value.join(',');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: context.canvasBackground.withValues(alpha: 0.95),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 54,
            child: OutlinedButton(
              onPressed: widget.onPrev,
              style: OutlinedButton.styleFrom(
                backgroundColor: context.cardSurface,
                foregroundColor: context.onCanvasText,
                side: BorderSide(color: context.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedPrimaryButton(
              text: 'Next',
              trailingIcon: Icons.arrow_forward,
              onPressed: () async {
                if (previewImages.value.isEmpty) {
                  AppToast.info(
                    context,
                    'Please upload at least one image',
                  );
                  return;
                }

                final featuredMedia = previewImages.value
                    .map(
                      (e) => FeaturedMediaModel.empty()
                          .copyWith(url: e, type: 'image'),
                    )
                    .toList();

                final workOrder = current.copyWith(
                  tags: _tagsController.text.trim(),
                  featuredMedia: featuredMedia,
                );

                context
                    .read<WorkOrderBloc>()
                    .add(PatchWorkOrder(workOrder));
                widget.onNext?.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickImages() async {
    final images = await picker.pickMultiImage(
      imageQuality: 70,
      limit: 4,
      requestFullMetadata: true,
    );
    if (images.isEmpty) return;

    pickedImages = images;
    final newPaths = images.map((img) => img.path).toSet();

    // 👇 Reactive update
    previewImages.value = {...previewImages.value, ...newPaths};
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    pickedImages.add(pickedFile);
    previewImages.value = {...previewImages.value, pickedFile.path};
  }
}