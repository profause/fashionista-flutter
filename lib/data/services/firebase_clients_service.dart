import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:flutter/foundation.dart';

abstract class FirebaseClientsService {
  Future<Either> fetchClientsFromFirestore(String uid);
  Future<Either> findClientByMobileNumber(String uid);
  Future<Either> findClientById(String uid);
  Future<Either> addClientToFirestore(Client client);
  Future<Either> updateClientToFirestore(Client client);
  Future<Either> deleteClientById(String uid);
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
      //debugPrint(clients.toString());
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
      //debugPrint(doc.data().toString());
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
      //debugPrint(clients.toString());
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

      debugPrint("Client with UID $uid deleted successfully.");
      return const Right('successfully deleted client'); // success without data
    } on FirebaseException catch (e) {
      debugPrint("Firestore error: ${e.message}");
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      debugPrint("Unexpected error: $e");
      return Left(e.toString());
    }
  }
}
