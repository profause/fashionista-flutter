import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/domain/repository/clients/clients_repository.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  @override
  Future<Either> addClientToFirestore(Client client) async {
    return sl<FirebaseClientsService>().addClientToFirestore(client);
  }

  @override
  Future<Either> fetchClientsFromFirestore(String uid) {
    return sl<FirebaseClientsService>().fetchClientsFromFirestore(uid);
  }

  @override
  Future<Either> updateClientToFirestore(Client client) {
    return sl<FirebaseClientsService>().updateClientToFirestore(client);
  }

  @override
  Future<Either> deleteClientById(String clientId) {
    return sl<FirebaseClientsService>().deleteClientById(clientId);
  }

  @override
  Future<Either> findClientById(String clientId) {
    return sl<FirebaseClientsService>().findClientById(clientId);
  }

  @override
  Future<Either<String, List<Client>>> findClientsFromFirestore(String uid) {
    return sl<FirebaseClientsService>().findClientsFromFirestore(uid);
  }

  @override
  Future<Either> fetchPinnedClients(List<String> clientIds) {
    return sl<FirebaseClientsService>().fetchPinnedClients();
  }

  @override
  Future<bool> isPinnedClient(String clientId) {
    return sl<FirebaseClientsService>().isPinnedClient(clientId);
  }

  @override
  Future<Either> pinOrUnpinClient(String clientId) {
    return sl<FirebaseClientsService>().pinOrUnpinClient(clientId);
  }
}
