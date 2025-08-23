import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultiImageUploader extends StatefulWidget {
  final String userId;

  const MultiImageUploader({super.key, required this.userId});

  @override
  State<MultiImageUploader> createState() => _MultiImageUploaderState();
}

class _MultiImageUploaderState extends State<MultiImageUploader> {
  final ImagePicker picker = ImagePicker();
  List<XFile> pickedImages = [];
  List<double> uploadProgress = [];
  List<String> uploadedUrls = [];

  bool isUploading = false;

  /// Pick multiple images
  Future<void> pickImages() async {
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      pickedImages = images;
      uploadProgress = List.filled(images.length, 0.0);
      uploadedUrls.clear();
    });
  }

  /// Upload all images
  Future<void> uploadImages() async {
    if (pickedImages.isEmpty) return;

    setState(() => isUploading = true);

    final storage = FirebaseStorage.instance;
    final uploadTasks = <Future<String>>[];

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      uploadTasks.add(() async {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref().child("designer_images/${widget.userId}/$fileName.jpg");

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
      await FirebaseFirestore.instance.collection("designers").doc(widget.userId).set({
        "featured_images": FieldValue.arrayUnion(urls),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Images uploaded successfully!")),
      );
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }
  }

  /// Delete image from Firebase Storage & Firestore
  Future<void> deleteImage(String url) async {
    try {
      // Delete from storage
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();

      // Delete from Firestore
      await FirebaseFirestore.instance.collection("designers").doc(widget.userId).update({
        "featured_images": FieldValue.arrayRemove([url]),
      });

      setState(() {
        uploadedUrls.remove(url);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Image deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to delete: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pick Button
        ElevatedButton.icon(
          onPressed: pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text("Pick Images"),
        ),

        // Upload Button
        if (pickedImages.isNotEmpty)
          ElevatedButton.icon(
            onPressed: isUploading ? null : uploadImages,
            icon: const Icon(Icons.cloud_upload),
            label: Text(isUploading ? "Uploading..." : "Upload Images"),
          ),

        const SizedBox(height: 16),

        // Show Uploaded Images from Firestore
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection("designers").doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data?.data() == null) {
              return const SizedBox();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final photos = List<String>.from(data["featured_images"] ?? []);

            if (photos.isEmpty) {
              return const Text("No images uploaded yet.");
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final url = photos[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => deleteImage(url),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
