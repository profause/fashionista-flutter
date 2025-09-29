import 'dart:io';

import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WorkOrderTimelineScreen extends StatefulWidget {
  final WorkOrderModel workOrderInfo; // 👈 workOrderInfo
  const WorkOrderTimelineScreen({super.key, required this.workOrderInfo});

  @override
  State<WorkOrderTimelineScreen> createState() =>
      _WorkOrderTimelineScreenState();
}

class _WorkOrderTimelineScreenState extends State<WorkOrderTimelineScreen> {
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text('Project Timeline'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        // 👈 makes sure it stays below status bar
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, right: 16),
                child: Text(
                  textAlign: TextAlign.start,
                  'Stay on top of deadlines, updates, and progress — all in one place.',
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 40, // default is 48
        child: FloatingActionButton.extended(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          onPressed: () {
            debugPrint("Update timeline");
            _showFilterBottomsheet(context);
          },
          label: Text(
            "Update timeline",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomsheet(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final TextEditingController statusTextFieldController =
        TextEditingController();
    final TextEditingController descriptionTextFieldController =
        TextEditingController();

    List<XFile> previewImages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.7,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Handle bar
                        Center(
                          child: Container(
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Text(
                          "Provide details of the progress you have made so far.",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomTextInputFieldWidget(
                                  autofocus: true,
                                  controller: statusTextFieldController,
                                  hint:
                                      'Status... eg: knitting, cutting, sewing',
                                  validator: (value) {
                                    if ((value ?? "").isEmpty) {
                                      return 'Enter status to get started...';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const Divider(height: .1, thickness: .1),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomTextInputFieldWidget(
                                  autofocus: false,
                                  controller: descriptionTextFieldController,
                                  hint:
                                      'Describe the progress you have made so far...',
                                  minLines: 2,
                                  maxLength: 150,
                                  validator: (value) {
                                    if ((value ?? "").isEmpty) {
                                      return 'Describe the progress you have made so far...';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Featured images can help you share your progress with your clients.",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              if (previewImages.isNotEmpty) ...[
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                setModalState(() {
                                                  previewImages.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black54,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
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
                              ],
                              if (previewImages.length < 2) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    CustomIconButtonRounded(
                                      onPressed: () {
                                        //if (true) return;
                                        _pickImages(context, (images) {
                                          //set images to previewImages[]
                                          setModalState(() {
                                            previewImages.addAll(images);
                                          });
                                        });
                                      },
                                      iconData: Icons.image_outlined,
                                    ),
                                    const SizedBox(width: 16),
                                    CustomIconButtonRounded(
                                      onPressed: () {
                                        _captureImage(ImageSource.camera, (
                                          image,
                                        ) {
                                          //set images to previewImages[]
                                          setModalState(() {
                                            previewImages.add(image);
                                          });
                                        });
                                      },
                                      iconData: Icons.camera_alt_outlined,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              //const Divider(height: .1, thickness: .1),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity, // takes full available width
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                                  colorScheme.surface, // solid grey background
                              foregroundColor:
                                  colorScheme.onSurface, // text/icon color
                            ),
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _captureImage(
    ImageSource source,
    Function(XFile image) onImagePicked,
  ) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      onImagePicked(pickedFile);
    }
    if (mounted) {
      // Dismiss the dialog manually
      //Navigator.of(context, rootNavigator: true).pop();
    }
    //_cropImage();
  }

  Future<void> _pickImages(
    BuildContext context,
    Function(List<XFile> pickedImages) onImagePicked,
  ) async {
    final images = await picker.pickMultiImage(
      imageQuality: 70,
      limit: 4,
      requestFullMetadata: true,
    );
    if (images.isEmpty) return;
    onImagePicked(images);
  }
}
