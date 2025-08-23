import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/deletable_image_widget.dart';
import 'package:fashionista/presentation/widgets/fullscreen_gallery_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeaturedImagesWidget extends StatefulWidget {
  final Designer designer;
  const FeaturedImagesWidget({super.key, required this.designer});

  @override
  State<FeaturedImagesWidget> createState() => _FeaturedImagesWidgetState();
}

class _FeaturedImagesWidgetState extends State<FeaturedImagesWidget> {
  final ImagePicker picker = ImagePicker();
  List<XFile> pickedImages = [];
  List<double> uploadProgress = [];
  List<String> uploadedUrls = [];

  bool isUploading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<DesignerBloc, DesignerState>(
      builder: (context, state) {
        return Card(
          color: colorScheme.onPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // instead of circular(0)
          ),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: double.infinity, // 👈 makes the card full width
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Featured Images', style: textTheme.titleSmall),
                      if (widget.designer.featuredImages!.length < 4) ...[
                        const Spacer(),
                        Stack(
                          children: [
                            if (isUploading) ...[
                              CircularProgressIndicator(strokeWidth: 3),
                            ],
                            CustomIconButtonRounded(
                              iconData: Icons.add_photo_alternate,
                              onPressed: () {
                                if (isUploading) return;
                                pickImages(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (widget.designer.featuredImages!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.designer.featuredImages!.length,
                        itemBuilder: (context, index) {
                          final imagePath =
                              widget.designer.featuredImages![index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullscreenGalleryWidget(
                                      images: widget.designer.featuredImages!,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: imagePath,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: DeletableImageWidget(
                                    imagePath: imagePath,
                                    onDelete: () =>
                                        deleteImage(imagePath, context),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> pickImages(BuildContext context) async {
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      pickedImages = images;
      uploadProgress = List.filled(images.length, 0.0);
      uploadedUrls.clear();
    });

    if (context.mounted) {
      uploadImages(context);
    }
  }

  Future<void> uploadImages(BuildContext context) async {
    if (pickedImages.isEmpty) return;

    setState(() => isUploading = true);

    final storage = FirebaseStorage.instance;
    final uploadTasks = <Future<String>>[];

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      uploadTasks.add(() async {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref().child(
          "designer_images/${widget.designer.uid}/$fileName.jpg",
        );

        final uploadTask = ref.putFile(File(image.path));

        // Track progress
        uploadTask.snapshotEvents.listen((snapshot) {
          final percent = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            uploadProgress[i] = percent;
          });
        });

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
      await FirebaseFirestore.instance
          .collection("designers")
          .doc(widget.designer.uid)
          .set({
            "featured_images": FieldValue.arrayUnion(urls),
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Images uploaded successfully!")),
      );
      context.read<DesignerBloc>().add(LoadDesigner(widget.designer.uid));
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
    }
  }

  /// Delete image from Firebase Storage & Firestore
  Future<void> deleteImage(String url, BuildContext context) async {
    try {
      // Delete from storage
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection("designers")
          .doc(widget.designer.uid)
          .update({
            "featured_images": FieldValue.arrayRemove([url]),
          });

      setState(() {
        uploadedUrls.remove(url);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("🗑️ Image deleted")));
      context.read<DesignerBloc>().add(LoadDesigner(widget.designer.uid));

    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to delete: $e")));
    }
  }
}
