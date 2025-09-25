import 'dart:io';

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
  List<double> uploadProgress = [];
  List<String> uploadedUrls = [];
  List<XFile> previewImages = [];
  bool isUploading = false;

  @override
  void initState() {
    current = WorkOrderModel.empty();
    _tagsController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _tagsController.dispose();
    previewImages.clear();
    pickedImages.clear();
    uploadedUrls.clear();
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
          builder: (context, state) {
            // ✅ pre-fill values when coming back
            if (state is WorkOrderUpdated) current = state.workorder;
            if (current.featuredMedia!.isNotEmpty) {
              for (var i = 0; i < current.featuredMedia!.length; i++) {
                previewImages.add(XFile(current.featuredMedia![i].url!));
              }
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Photos Gallery',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Upload photos of the work order',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 16),
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
                      onPressed: () {
                        _pickImage(ImageSource.camera);
                      },
                      iconData: Icons.camera_alt_outlined,
                    ),
                  ],
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
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onPrev,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Text('Previous'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        final featuredMedia = previewImages.map((e) {
                          return FeaturedMediaModel.empty().copyWith(
                            url: e.path,
                            type: 'image',
                          );
                        }).toList();
                        final workOrder = current.copyWith(
                          tags: _tagsController.text.trim(),
                          featuredMedia: featuredMedia,
                        );
                        context.read<WorkOrderBloc>().add(
                          UpdateWorkOrder(workOrder),
                        );
                        widget.onNext!();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
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
}
