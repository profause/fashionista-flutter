import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_measurement_relationship.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract class FirebaseClientsService {
  Future<Either> fetchClientsFromFirestore(String uid);
  Future<Either<String, List<Client>>> findClientsFromFirestore(String uid);
  Future<Either<String, List<Client>>> findClientByMobileNumber(
    String mobileNumber,
  );
  Future<Either<String, bool>> isMyClient(String mobileNumber);
  Future<Either> findClientById(String uid);
  Future<Either> addClientToFirestore(Client client);
  Future<Either> updateClientToFirestore(Client client);
  Future<Either> deleteClientById(String uid);
  Future<Either<String, int>> getCount(String uid);
  Future<bool> isPinnedClient(String uid);
  Future<Either> pinOrUnpinClient(String uid);
  Future<Either> fetchPinnedClients();
  Future<Either<String, List<ClientMeasurement>>> findMeasurementsByClientId(
    String clientId,
  );
  Future<Either<String, ClientMeasurement>> findMeasurementById(
    String clientId,
    String measurementId,
  );
  Future<Either<String, bool>> migrateLegacyMeasurements(String clientId);
  Future<Either<String, List<ClientMeasurementRelationship>>>
      findClientRelationshipsForUser(String userId);
  Future<Either<String, ClientMeasurementRelationship?>>
      findDefaultClientRelationship(String userId);
  Future<Either<String, void>> linkClientToUser({
    required String userId,
    required String clientId,
    bool isDefault = false,
    required String designId,
  });
  Future<Either<String, void>> setDefaultClientForUser({
    required String userId,
    required String clientId,
  });
  Future<Either<String, void>> unlinkClientFromUser({
    required String userId,
    required String clientId,
  });

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
  CollectionReference<Map<String, dynamic>> _measurementsCollection(
    String clientId,
  ) {
    return FirebaseFirestore.instance
        .collection('clients')
        .doc(clientId)
        .collection('measurements');
  }

  CollectionReference<Map<String, dynamic>> _clientRelationshipCollection(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('client_measurements')
        .doc(userId)
        .collection('clients');
  }

  Future<Client> _hydrateClientMeasurements(Client client) async {
    final measurementsResult = await findMeasurementsByClientId(client.uid);
    return measurementsResult.fold(
      (_) => client,
      (measurements) => client.copyWith(measurements: measurements),
    );
  }

  Map<String, dynamic> _clientPayloadForFirestore(Client client) {
    final payload = client.toJson();
    payload.remove('measurements');
    return payload;
  }

  @override
  Future<Either> addClientToFirestore(Client client) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final clientRef = firestore.collection('clients').doc(client.uid);
      final batch = firestore.batch();

      batch.set(
        clientRef,
        _clientPayloadForFirestore(client),
        SetOptions(merge: true),
      );

      for (final measurement in client.measurements) {
        batch.set(
          _measurementsCollection(client.uid).doc(measurement.uid),
          measurement.toFirestoreMap(clientId: client.uid),
          SetOptions(merge: true),
        );
      }

      await batch.commit();
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

      final clients = <Client>[];
      for (final doc in querySnapshot.docs) {
        final client = Client.fromJson(doc.data());
        clients.add(await _hydrateClientMeasurements(client));
      }

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

      final clients = <Client>[];
      for (final doc in querySnapshot.docs) {
        final client = Client.fromJson(doc.data());
        clients.add(await _hydrateClientMeasurements(client));
      }

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
      await firestore
          .collection('clients')
          .doc(client.uid)
          .set(_clientPayloadForFirestore(client), SetOptions(merge: true));
      return Right(client);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> findClientById(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('clients').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        return Left('Client not found');
      }
      final client = Client.fromJson(doc.data()!);
      return Right(await _hydrateClientMeasurements(client));
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either<String, List<Client>>> findClientByMobileNumber(
    String mobileNumber,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('clients')
          .where('mobile_number', isEqualTo: mobileNumber)
          .get();
      // Map each document to a Client. Docs written by older app versions can
      // be missing fields, so skip (and report) a malformed doc instead of
      // failing the whole list.
      final clients = <Client>[];
      for (final doc in querySnapshot.docs) {
        try {
          final client = Client.fromJson(doc.data());
          clients.add(await _hydrateClientMeasurements(client));
        } catch (e) {
          debugPrint('Skipping malformed client doc ${doc.id}: $e');
        }
      }
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
      final clientDoc = await firestore.collection('clients').doc(uid).get();
      final ownerUserId = clientDoc.data()?['created_by'] as String?;

      final measurementsSnapshot = await firestore
          .collection('clients')
          .doc(uid)
          .collection('measurements')
          .get();

      for (final measurement in measurementsSnapshot.docs) {
        await measurement.reference.delete();
      }

      final relationshipSnapshot = await FirebaseFirestore.instance
          .collectionGroup('clients')
          .where('client_id', isEqualTo: uid)
          .get();

      for (final relationship in relationshipSnapshot.docs) {
        await relationship.reference.delete();
      }

      if (ownerUserId != null && ownerUserId.isNotEmpty) {
        await unlinkClientFromUser(
          userId: ownerUserId,
          clientId: uid,
        );
      }

      await firestore.collection('clients').doc(uid).delete();

      return const Right('successfully deleted client');
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ClientMeasurement>>> findMeasurementsByClientId(
    String clientId,
  ) async {
    try {
      final snapshot = await _measurementsCollection(clientId).get();
      final measurements = snapshot.docs
          .map(
            (doc) => ClientMeasurement.fromFirestoreMap({
              ...doc.data(),
              'uid': doc.id,
            }),
          )
          .toList();
      return Right(measurements);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ClientMeasurement>> findMeasurementById(
    String clientId,
    String measurementId,
  ) async {
    try {
      final doc = await _measurementsCollection(
        clientId,
      ).doc(measurementId).get();
      if (!doc.exists || doc.data() == null) {
        return Left('Measurement not found');
      }

      final measurement = ClientMeasurement.fromFirestoreMap({
        ...doc.data()!,
        'uid': doc.id,
      });
      return Right(measurement);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> migrateLegacyMeasurements(
    String clientId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final clientDoc = await firestore
          .collection('clients')
          .doc(clientId)
          .get();
      if (!clientDoc.exists || clientDoc.data() == null) {
        return Left('Client not found');
      }

      final legacyMeasurements = clientDoc.data()!['measurements'];
      if (legacyMeasurements == null ||
          legacyMeasurements is! List ||
          legacyMeasurements.isEmpty) {
        return const Right(false);
      }

      for (final measurementData in legacyMeasurements) {
        if (measurementData is! Map<String, dynamic>) {
          continue;
        }

        final measurement = ClientMeasurement.fromJson(measurementData);
        await _measurementsCollection(clientId)
            .doc(measurement.uid)
            .set(
              measurement.toFirestoreMap(clientId: clientId),
              SetOptions(merge: true),
            );
      }

      return const Right(true);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ClientMeasurementRelationship>>>
      findClientRelationshipsForUser(String userId) async {
    try {
      final snapshot = await _clientRelationshipCollection(userId).get();
      final relationships = snapshot.docs
          .map(
            (doc) => ClientMeasurementRelationship.fromJson(doc.data()),
          )
          .toList();
      return Right(relationships);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to fetch client relationships');
    } catch (e) {
      return Left('Unable to fetch client relationships: $e');
    }
  }

  @override
  Future<Either<String, ClientMeasurementRelationship?>>
      findDefaultClientRelationship(String userId) async {
    try {
      final snapshot = await _clientRelationshipCollection(userId)
          .where('is_default', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Right(null);
      }

      return Right(
        ClientMeasurementRelationship.fromJson(snapshot.docs.first.data()),
      );
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to fetch the default client');
    } catch (e) {
      return Left('Unable to fetch the default client: $e');
    }
  }

  @override
  Future<Either<String, void>> linkClientToUser({
    required String userId,
    required String clientId,
    bool isDefault = false,
    required String designId,
  }) async {
    try {
      final docRef = _clientRelationshipCollection(userId).doc(clientId);
      final snapshot = await docRef.get();
      final nextIsDefault = snapshot.exists
          ? (snapshot.data()?['is_default'] == true || isDefault)
          : isDefault;

      await docRef.set(
        {
          'client_id': clientId,
          'is_default': nextIsDefault,
        },
        SetOptions(merge: true),
      );
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to link client to user');
    } catch (e) {
      return Left('Unable to link client to user: $e');
    }
  }

  @override
  Future<Either<String, void>> setDefaultClientForUser({
    required String userId,
    required String clientId,
  }) async {
    try {
      final relationshipRef = _clientRelationshipCollection(userId).doc(clientId);
      final snapshot = await relationshipRef.get();
      if (!snapshot.exists) {
        return const Left('Client is not linked to this user');
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final allRelationships = await _clientRelationshipCollection(userId).get();

        for (final doc in allRelationships.docs) {
          if (doc.id != clientId && doc.data()['is_default'] == true) {
            transaction.update(doc.reference, {'is_default': false});
          }
        }

        transaction.update(relationshipRef, {'is_default': true});
      });

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to update the default client');
    } catch (e) {
      return Left('Unable to update the default client: $e');
    }
  }

  @override
  Future<Either<String, void>> unlinkClientFromUser({
    required String userId,
    required String clientId,
  }) async {
    try {
      final docRef = _clientRelationshipCollection(userId).doc(clientId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return const Right(null);
      }

      final isDefault = snapshot.data()?['is_default'] == true;
      await docRef.delete();

      if (isDefault) {
        final remaining = await _clientRelationshipCollection(userId).limit(1).get();
        if (remaining.docs.isNotEmpty) {
          await remaining.docs.first.reference.update({'is_default': true});
        }
      }

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to unlink client from user');
    } catch (e) {
      return Left('Unable to unlink client from user: $e');
    }
  }

  @override
  Future<Either> updateClientMeasurementToFirestore(
    Client client,
    ClientMeasurement clientMeasurement,
  ) async {
    try {
      await _measurementsCollection(client.uid)
          .doc(clientMeasurement.uid)
          .set(
            clientMeasurement.toFirestoreMap(clientId: client.uid),
            SetOptions(merge: true),
          );
      return Right(clientMeasurement);
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
      await _measurementsCollection(
        clientId,
      ).doc(clientMeasurement.uid).delete();
      return Right('measurement deleted successfully');
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> updateClientMeasurement(Client client) async {
    try {
      for (final measurement in client.measurements) {
        final measurementId = measurement.uid.trim();
        final safeMeasurement = measurementId.isEmpty
            ? ClientMeasurement.empty().copyWith(
                bodyPart: measurement.bodyPart,
                measuringUnit: measurement.measuringUnit,
                notes: measurement.notes,
                previousValues: measurement.previousValues,
                tags: measurement.tags,
                measuredValue: measurement.measuredValue,
                updatedDate: measurement.updatedDate,
              )
            : measurement;

        await _measurementsCollection(client.uid)
            .doc(safeMeasurement.uid)
            .set(
              safeMeasurement.toFirestoreMap(clientId: client.uid),
              SetOptions(merge: true),
            );
      }

      return Right('measurement updated successfully');
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

      final clients = <Client>[];
      for (final doc in querySnapshot.docs) {
        final client = Client.fromJson(doc.data());
        clients.add(await _hydrateClientMeasurements(client));
      }

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
