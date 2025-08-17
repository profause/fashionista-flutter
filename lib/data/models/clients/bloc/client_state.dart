import 'package:fashionista/data/models/clients/client_model.dart';

abstract class ClientState {
  get client => null;
}
class ClientLoaded extends ClientState {
  @override
  final Client client;
  ClientLoaded({required this.client});
}

class ClientUpdated extends ClientState {
  @override
  final Client client;

  ClientUpdated({required this.client});
}

class ClientDeleted extends ClientState {
  final String message;
  ClientDeleted({required this.message});
}
