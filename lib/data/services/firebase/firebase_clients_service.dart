import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';

abstract class FirebaseClientsService {
  Future<Either> fetchClientsFromFirestore(String uid);
  Future<Either<String,List<Client>>> findClientsFromFirestore(String uid);
  Future<Either> findClientByMobileNumber(String uid);
  Future<Either> findClientById(String uid);
  Future<Either> addClientToFirestore(Client client);
  Future<Either> updateClientToFirestore(Client client);
  Future<Either> deleteClientById(String uid);
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
}
