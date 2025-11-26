import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseClientsService {
  Future<Either> fetchClientsFromFirestore(String uid);
  Future<Either<String, List<Client>>> findClientsFromFirestore(String uid);
  Future<Either> findClientByMobileNumber(String mobileNumber);
   Future<Either<String, bool>> isMyClient(String mobileNumber);
  Future<Either> findClientById(String uid);
  Future<Either> addClientToFirestore(Client client);
  Future<Either> updateClientToFirestore(Client client);
  Future<Either> deleteClientById(String uid);
  Future<Either<String, int>> getCount(String uid);
  Future<bool> isPinnedClient(String uid);
  Future<Either> pinOrUnpinClient(String uid);
  Future<Either> fetchPinnedClients();

  Future<Either> updateClientMeasurementToFirestore(
    Client client,
    ClientMeasurement clientMeasurement,
  );
  Future<Either> deleteClientMeasurementFromFirestore(
    String clientId,
    ClientMeasurement clientMeasurement,
  );

  Future<Either> updateClientMeasurement(Client clientId);
}

class FirebaseClientsServiceImpl implements FirebaseClientsService {
  @override
  Future<Either> addClientToFirestore(Client client) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('clients')
          .doc(client.uid)
          .set(client.toJson(), SetOptions(merge: true));
      return Right(client);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either<String, List<Client>>> fetchClientsFromFirestore(
    String uid,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('clients')
          .where('created_by', isEqualTo: uid)
          .orderBy('created_date', descending: true)
          .get();

      final clients = querySnapshot.docs.map((doc) {
        final d = Client.fromJson(doc.data());
        return d;
      }).toList();

      // Map each document to a client
      return Right(clients);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<Client>>> findClientsFromFirestore(
    String uid,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('clients')
          .where('created_by', isEqualTo: uid)
          .orderBy('created_date', descending: true)
          .get();

      final clients = querySnapshot.docs.map((doc) {
        final d = Client.fromJson(doc.data());
        return d;
      }).toList();

      // Map each document to a client
      return Right(clients);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateClientToFirestore(Client client) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('clients')
          .doc(client.uid)
          .set(client.toJson(), SetOptions(merge: true));
      return Right(client);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> findClientById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('clients').doc(uid);
      DocumentSnapshot doc = await docRef.get();
      Client client = Client.fromJson(doc.data() as Map<String, dynamic>);
      return Right(client);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> findClientByMobileNumber(String mobileNumber) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('clients')
          .where('mobile_number', isEqualTo: mobileNumber)
          .get();
      // Map each document to a Client
      final clients = querySnapshot.docs
          .map((doc) => Client.fromJson(doc.data()))
          .toList();
      return Right(clients);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> isMyClient(String mobileNumber) async {
    try {
      final firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore
          .collection('clients')
          .where('mobile_number', isEqualTo: mobileNumber)
          .where(
            'created_by',
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          )
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return Left('No user found');
      }
      bool isMyClient = querySnapshot.docs.first.data() != null;
      return Right(isMyClient);
    } on FirebaseException catch (e) {
      return Left(e.message!);
    }
  }

  @override
  Future<Either<String, String>> deleteClientById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete the document with the given uid
      await firestore.collection('clients').doc(uid).delete();

      return const Right('successfully deleted client'); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateClientMeasurementToFirestore(
    Client client,
    ClientMeasurement clientMeasurement,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('clients').doc(client.uid).update({
        "measurements": FieldValue.arrayUnion(client.measurements),
      });
      return Right(client);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteClientMeasurementFromFirestore(
    String clientId,
    ClientMeasurement clientMeasurement,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('clients').doc(clientId).update({
        "measurements": FieldValue.arrayRemove([clientMeasurement]),
      });
      return Right('measurement deleted successfully');
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateClientMeasurement(Client client) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('clients')
          .doc(client.uid);

      // Get current measurements
      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (data == null) return Left('No data found');

      final clientT = Client.fromJson(data);
      List measurementsToRemove = clientT.measurements
          .map((m) => m.toJson())
          .toList();

      List measurementsToAdd = client.measurements
          .map((m) => m.toJson())
          .toList();

      await docRef.update({
        "measurements": FieldValue.arrayRemove(measurementsToRemove),
      });

      await docRef.update({
        "measurements": FieldValue.arrayUnion(measurementsToAdd),
      });

      return Right('measurement deleted successfully');
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> fetchPinnedClients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left('No user logged in');
      }
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('clients')
          .where('created_by', isEqualTo: userId)
          .where('is_pinned', isEqualTo: true)
          .orderBy('created_date', descending: true)
          .get();

      final clients = querySnapshot.docs.map((doc) {
        final d = Client.fromJson(doc.data());
        return d;
      }).toList();

      // Map each document to a client
      return Right(clients);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> isPinnedClient(String clientId) async {
    try {
      final us = FirebaseAuth.instance.currentUser;
      if (us == null) {
        return false;
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final firestore = FirebaseFirestore.instance;
      late bool isPinned;
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('pinned_clients')
          .where('client_id', isEqualTo: clientId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isPinned = false;
      } else {
        isPinned = true;
      }
      return isPinned;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either> pinOrUnpinClient(String clientId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore.collection('clients').doc(clientId);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('client not found');
      }
      Client client = Client.fromJson(doc.data() as Map<String, dynamic>);
      bool isPinned = client.isPinned ?? false;
      client = client.copyWith(isPinned: !isPinned);
      updateClientToFirestore(client);

      return Right(client.isPinned);
    } on FirebaseException catch (e) {
      return Left(e.message!);
    }
  }

  @override
  Future<Either<String, int>> getCount(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('clients')
          .where('created_by', isEqualTo: uid)
          .count()
          .get();

      final clientsCount = querySnapshot.count;

      //await importTrends(sampleTrendsData);
      return Right(clientsCount ?? 0);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
