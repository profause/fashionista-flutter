import 'package:fashionista/data/models/clients/client_model.dart';

abstract class ClientState {}

class ClientInitial extends ClientState {}

class ClientLoaded extends ClientState {
  final Client client;
  ClientLoaded({required this.client});
}

class ClientUpdated extends ClientState {
  final Client client;

  ClientUpdated({required this.client});
}

class ClientDelete extends ClientState {
  final String message;
  ClientDelete({required this.message});
}
