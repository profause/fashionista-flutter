import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

abstract class FirebaseDesignCollectionService {
  Future<Either> fetchDesignCollections();
  Future<Either> findDesignCollections(String createdBy);
  Future<Either> addDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  );
  Future<Either> updateDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  );
  Future<Either> findDesignCollectionById(String uid);
  Future<Either> deleteDesignCollectionById(String uid);
  Future<Either> deleteDesignCollectionImage(String imageUrl);
  Future<bool> isBookmarkedDesignCollection(String uid);
  Future<Either> addOrRemoveBookmarkDesignCollection(String uid);
  Future<Either> fetchBookmarkedDesignCollections(List<String> uids);
}

class FirebaseDesignCollectionServiceImpl
    implements FirebaseDesignCollectionService {
  @override
  Future<Either> fetchDesignCollections() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('design_collections')
          //.where('created_by', isEqualTo: createdBy)
          .get();
      // Map each document to a DesignCollection
      final designCollection = querySnapshot.docs.map((doc) {
        //bool isFavourite = await isFavouriteDesigner(doc.reference.id);
        final d = DesignCollectionModel.fromJson(doc.data());
        return d; //.copyWith(isFavourite: isFavourite);
      }).toList();
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> addDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('design_collections')
          .doc(designCollection.uid)
          .set(designCollection.toJson(), SetOptions(merge: true));
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteDesignCollectionById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete the document with the given uid
      await firestore.collection('design_collections').doc(uid).delete();
      return Right(
        'successfully deleted design collection $uid',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> findDesignCollectionById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore
          .collection('design_collections')
          .doc(uid);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('Design Collection not found');
      }

      DesignCollectionModel designCollection = DesignCollectionModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateDesignCollectionToFirestore(
    DesignCollectionModel designCollection,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('design_collections')
          .doc(designCollection.uid)
          .set(designCollection.toJson(), SetOptions(merge: true));
      return Right(designCollection);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> findDesignCollections(String createdBy) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('design_collections')
          .where('created_by', isEqualTo: createdBy)
          .where('visibility', isEqualTo: 'public')
          .orderBy('created_at', descending: true)
          .get();

      // Await all async maps
      final designCollections = await Future.wait(
        querySnapshot.docs.map((doc) async {
          bool isBookmarked = await isBookmarkedDesignCollection(
            doc.reference.id,
          );
          final d = DesignCollectionModel.fromJson(doc.data());
          return d.copyWith(uid: doc.reference.id, isBookmarked: isBookmarked);
        }),
      );

      //await importCollections(sampleDesignCollections);

      return Right(designCollections);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  final List<Map<String, dynamic>> sampleDesignCollections = [
    {
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "title": "Summer Breeze Collection",
      "description":
          "A collection of light and vibrant summer outfits perfect for beach days and casual outings.",
      "tags": "summer|casual|beachwear|fashion",
      "visibility": "public",
      "featured_images": [
        "https://placehold.co/180x280.png?text=Summer1",
        "https://placehold.co/180x280.png?text=Summer2",
        "https://placehold.co/180x280.png?text=Summer3",
      ],
      "author": {
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "name": "Emmanuel Mensah",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "created_at": 1750003200000,
      "updated_at": 1755648000000,
      "credits": "Photography by Ama K.|Styling by Kwame A.",
    },
    {
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "title": "Urban Nights",
      "description":
          "Streetwear inspired collection with bold colors and sharp silhouettes for night events.",
      "tags": "streetwear|nightlife|urban|fashion",
      "visibility": "public",
      "featured_images": [
        "https://placehold.co/180x280.png?text=Urban1",
        "https://placehold.co/180x280.png?text=Urban2",
      ],
      "author": {
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "name": "Emmanuel Mensah",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "created_at": 1746835200000,
      "updated_at": 1755734400000,
      "credits": "Lighting by Joe K.|Accessories by Akosua T.",
    },
    {
      "created_by": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
      "title": "Bridal Elegance",
      "description":
          "Elegant and timeless bridal dresses made with luxurious fabrics.",
      "tags": "bridal|wedding|elegance|fashion",
      "visibility": "private",
      "featured_images": [
        "https://placehold.co/180x280.png?text=Bridal1",
        "https://placehold.co/180x280.png?text=Bridal2",
      ],
      "author": {
        "uid": "7cv6Kz3nduUhSjb8U0UEp2F379h1",
        "name": "Emmanuel Mensah",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "created_at": 1739491200000,
      "updated_at": 1756070400000,
      "credits": "Makeup by Linda B.|Jewelry by Kobby J.",
    },
    {
      "created_by": "dIWRJLg295RbkCMKgNGi0HlSQBX2",
      "title": "Cultural Fusion",
      "description":
          "A vibrant mix of African prints and western styles for a unique cultural blend.",
      "tags": "african|culture|prints|fashion",
      "visibility": "public",
      "featured_images": [
        "https://placehold.co/180x280.png?text=Cultural1",
        "https://placehold.co/180x280.png?text=Cultural2",
        "https://placehold.co/180x280.png?text=Cultural3",
      ],
      "author": {
        "uid": "dIWRJLg295RbkCMKgNGi0HlSQBX2",
        "name": "Emmanuel Mensah",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "created_at": 1751328000000,
      "updated_at": 1755475200000,
      "credits": "Models by Elite Agency|Styling by Efua M.",
    },
    {
      "created_by": "dIWRJLg295RbkCMKgNGi0HlSQBX2",
      "title": "Minimal Luxe",
      "description":
          "Sleek, minimalistic designs with premium materials for the modern professional.",
      "tags": "minimal|luxe|modern|workwear",
      "visibility": "public",
      "featured_images": [
        "https://picsum.photos/seed/picsum/180/280",
        "https://placehold.co/180x280.png?text=Minimal1",
        "https://placehold.co/180x280.png?text=Minimal2",
      ],
      "author": {
        "uid": "dIWRJLg295RbkCMKgNGi0HlSQBX2",
        "name": "Emmanuel Mensah",
        "avatar":
            "https://firebasestorage.googleapis.com/v0/b/fashionista-2025.firebasestorage.app/o/profile_images%2FdIWRJLg295RbkCMKgNGi0HlSQBX2.jpg?alt=media&token=c774ed83-d55e-4336-9600-0d4ec586631f",
      },
      "created_at": 1741382400000,
      "updated_at": 1756166400000,
      "credits": "Creative direction by Nana Y.|Photos by Bright Studios.",
    },
  ];

  Future<void> importCollections(List<Map<String, dynamic>> data) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (var item in data) {
      final docRef = firestore
          .collection('design_collections')
          .doc(); // auto-ID
      batch.set(docRef, item);
    }

    await batch.commit();
    print('✅ Data imported successfully!');
  }

  @override
  Future<Either> addOrRemoveBookmarkDesignCollection(
    String designCollectionId,
  ) async {
    try {
      final us = firebase_auth.FirebaseAuth.instance.currentUser;
      if (us == null) {
        return Left('User not logged in');
      }
      String uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isBookmarked;
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('bookmarked_design_collections')
          .where('design_collection_id', isEqualTo: designCollectionId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await firestore
            .collection('users')
            .doc(uid)
            .collection('bookmarked_design_collections')
            .doc(designCollectionId)
            .set({
              'design_collection_id': designCollectionId,
              'created_at': Timestamp.now(),
            }, SetOptions(merge: true));
        isBookmarked = true;
      } else {
        await querySnapshot.docs.first.reference.delete();
        isBookmarked = false;
      }
      return Right(isBookmarked);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> fetchBookmarkedDesignCollections(List<String> uids) async {
    try {
      if (uids.isEmpty) return Right([]);

      final chunks = <List<String>>[];
      for (var i = 0; i < uids.length; i += 10) {
        chunks.add(
          uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10),
        );
      }
      final results = await Future.wait(
        chunks.map((chunk) {
          return FirebaseFirestore.instance
              .collection('design_collections')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
        }),
      );

      final designers = results
          .expand((querySnapshot) => querySnapshot.docs)
          .map((doc) => DesignCollectionModel.fromJson(doc.data()))
          .toList();

      return Right(designers);
    } on FirebaseException catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> isBookmarkedDesignCollection(String designCollectionId) async {
    try {
      final us = firebase_auth.FirebaseAuth.instance.currentUser;
      if (us == null) {
        return false;
      }
      String uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      late bool isBookmarked;
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('bookmarked_design_collections')
          .where('design_collection_id', isEqualTo: designCollectionId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isBookmarked = false;
      } else {
        isBookmarked = true;
      }
      return isBookmarked;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either> deleteDesignCollectionImage(String imageUrl) async {
    try {
      // Delete from storage
      CloudinaryConfig config = CloudinaryConfig.fromUri(
        appConfig.get('cloudinary_url'),
      );
      final cloudinary = Cloudinary.fromConfiguration(config);
      DestroyParams destroyParams = DestroyParams(publicId: imageUrl);
      await cloudinary.uploader().destroy(destroyParams);
      return Right('Image deleted');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
