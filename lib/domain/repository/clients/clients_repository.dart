import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/clients/client_model.dart';

abstract class ClientsRepository {
  Future<Either> fetchClientsFromFirestore(String uid);
  Future<Either<String, List<Client>>> findClientsFromFirestore(String uid);
  Future<Either> addClientToFirestore(Client client);
  Future<Either> updateClientToFirestore(Client client);
  Future<Either> deleteClientById(String clientId);
  Future<Either> findClientById(String clientId);

  Future<bool> isPinnedClient(String clientId);
  Future<Either> pinOrUnpinClient(String clientId);
  Future<Either> fetchPinnedClients(List<String> clientIds);
}
