import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';

class ClientBlocState extends Equatable {
  const ClientBlocState();
  @override
  List<Object?> get props => [];
}

class ClientInitial extends ClientBlocState {
  const ClientInitial();
}

class ClientLoading extends ClientBlocState {
  const ClientLoading();
}

class ClientLoaded extends ClientBlocState {
  final Client client;
  const ClientLoaded(this.client);

  @override
  List<Object?> get props => [client];
}

class ClientUpdated extends ClientBlocState {
  final Client client;
  const ClientUpdated(this.client);
  @override
  List<Object?> get props => [client];
}

class ClientsLoaded extends ClientBlocState {
  final List<Client> clients;
  final bool fromCache;
  const ClientsLoaded(this.clients, {this.fromCache = false});

  @override
  List<Object?> get props => [clients];
}

class ClientsEmpty extends ClientBlocState {
  const ClientsEmpty();
}

class ClientError extends ClientBlocState {
  final String message;
  const ClientError(this.message);

  @override
  List<Object?> get props => [message];
}

class ClientsNewData extends ClientBlocState {
  final List<Client> clients;
  const ClientsNewData(this.clients);

  @override
  List<Object?> get props => [clients];
}

class ClientDeleted extends ClientBlocState {
  final String message;
  const ClientDeleted(this.message);
  @override
  List<Object?> get props => [message];
}
