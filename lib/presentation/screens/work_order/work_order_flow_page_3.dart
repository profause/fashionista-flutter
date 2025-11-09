import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                Text('Photo Gallery',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('Upload photos of the work order',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),

                /// 👇 REACTIVE IMAGE LIST
                ValueListenableBuilder<Set<String>>(
                  valueListenable: previewImages,
                  builder: (context, images, _) {
                    if (images.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final list = images.toList();
                    return SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final image = list[index];
                          return Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 3 / 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: image.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: image,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child: SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  const Icon(Icons.broken_image),
                                        )
                                      : Image.file(
                                          File(image),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    previewImages.value = {
                                      ...images..remove(image),
                                    };
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
                    );
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    CustomIconButtonRounded(
                      onPressed: () {
                        if (isUploading) return;
                        pickImages();
                      },
                      iconData: Icons.image_outlined,
                    ),
                    const SizedBox(width: 16),
                    CustomIconButtonRounded(
                      onPressed: () => _pickImage(ImageSource.camera),
                      iconData: Icons.camera_alt_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    CustomIconRounded(icon: Icons.tag, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TagInputField(
                        label:
                            'What are the style inspirations behind this project?',
                        hint:
                            'Type and press Enter, Space or Comma to add a tag',
                        valueIn: current.tags!.isEmpty
                            ? []
                            : current.tags!.split(',').toList(),
                        valueOut: (value) {
                          _tagsController.text = value.join(',');
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onPrev,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text('Previous'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        if (previewImages.value.isEmpty) {
                            AppToast.info(context, 'Please upload at least one image');
                          return;
                        }

                        final featuredMedia = previewImages.value
                            .map((e) => FeaturedMediaModel.empty()
                                .copyWith(url: e, type: 'image'))
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Next'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
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

