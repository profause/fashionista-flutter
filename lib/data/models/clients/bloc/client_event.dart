import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/clients/client_model.dart';

abstract class ClientBlocEvent extends Equatable {
  const ClientBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadClient extends ClientBlocEvent {
  final String uid;
  const LoadClient(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateClient extends ClientBlocEvent {
  final Client client;
  const UpdateClient(this.client);

  @override
  List<Object?> get props => [client];
}

class AddClient extends ClientBlocEvent {
  final Client client;
  const AddClient(this.client);

  @override
  List<Object?> get props => [client];
}

class LoadClients extends ClientBlocEvent {
  final String uid;
  const LoadClients(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadClientsCacheFirstThenNetwork extends ClientBlocEvent {
  final String uid;
  const LoadClientsCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ClientsCounter extends ClientBlocEvent {
  final String uid;
  const ClientsCounter(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteClient extends ClientBlocEvent {
  final String uid;
  const DeleteClient(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ClearClient extends ClientBlocEvent {
  const ClearClient();
}
