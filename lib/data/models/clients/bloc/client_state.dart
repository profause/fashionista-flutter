import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/clients/client_model.dart';

class ClientBlocState extends Equatable {
  final int clientsCount;
  const ClientBlocState({this.clientsCount = 0});
  @override
  List<Object?> get props => [clientsCount];
}

class ClientInitial extends ClientBlocState {
  const ClientInitial({super.clientsCount = 0});
}

class ClientLoading extends ClientBlocState {
  const ClientLoading({super.clientsCount = 0});
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
  const ClientsLoaded(this.clients, {this.fromCache = false})
    : super(clientsCount: clients.length);

  @override
  List<Object?> get props => [clients, fromCache, clientsCount];
}

class ClientsCounted extends ClientBlocState {
  const ClientsCounted(int count) : super(clientsCount: count);
  @override
  List<Object?> get props => [clientsCount];
}

class ClientsEmpty extends ClientBlocState {
  const ClientsEmpty();
}

class ClientError extends ClientBlocState {
  final String message;
  const ClientError(this.message, {super.clientsCount = 0});

  @override
  List<Object?> get props => [message, clientsCount];
}

class ClientsNewData extends ClientBlocState {
  final List<Client> clients;
  const ClientsNewData(this.clients);

  @override
  List<Object?> get props => [clients];
}

class ClientDeleted extends ClientBlocState {
  final String message;
  const ClientDeleted(this.message, {super.clientsCount = 0});
  @override
  List<Object?> get props => [message, clientsCount];
}
