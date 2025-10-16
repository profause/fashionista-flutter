import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/domain/usecases/clients/add_client_usecase.dart';
import 'package:fashionista/domain/usecases/clients/delete_client_usecase.dart';
import 'package:fashionista/domain/usecases/clients/find_client_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/clients/find_clients_usecase.dart';
import 'package:fashionista/domain/usecases/clients/update_client_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientBloc extends Bloc<ClientBlocEvent, ClientBlocState> {
  ClientBloc() : super(const ClientInitial()) {
    on<LoadClient>(_onLoadClient);
    on<LoadClients>(_onLoadClients);
    on<UpdateClient>(_updateClient);
    on<AddClient>(_addClient);
    on<DeleteClient>(_deleteClient);
    //on<UpdateClient>((event, emit) => emit(ClientUpdated(event.client)));
    on<LoadClientsCacheFirstThenNetwork>(_onLoadClientsCacheFirstThenNetwork);
    on<ClearClient>((event, emit) => emit(const ClientInitial()));
    on<ClientsCounter>(_onCountClients);
  }

  Future<void> _onLoadClient(
    LoadClient event,
    Emitter<ClientBlocState> emit,
  ) async {
    emit(const ClientLoading());
    if (event.isFromCache) {
      // 1️⃣ Try cache first
      final cachedItem = await sl<HiveClientService>().getItem(event.uid);
      emit(ClientUpdated(cachedItem));
    } else {
      final result = await sl<FindClientByIdUsecase>().call(event.uid);
      result.fold(
        (failure) => emit(ClientError(failure.toString())),
        (client) => emit(ClientUpdated(client)),
      );
    }
  }

  Future<void> _deleteClient(
    DeleteClient event,
    Emitter<ClientBlocState> emit,
  ) async {
    try {
      var result = await sl<DeleteClientUsecase>().call(event.uid);

      await result.fold(
        (failure) async {
          emit(ClientError(failure.toString()));
        },
        (message) async {
          await sl<HiveClientService>().deleteItem(event.uid);
          emit(ClientDeleted(message)); // ✅ safe emit
        },
      );
    } catch (e) {
      // ❌ Rollback if persistence failed (optional)
      emit(ClientError("Failed to delete item: $e"));
    }
  }

  Future<void> _onLoadClients(
    LoadClients event,
    Emitter<ClientBlocState> emit,
  ) async {
    emit(const ClientLoading());

    final result = await sl<FindClientsUsecase>().call(event.uid);

    result.fold((failure) => emit(ClientError(failure.toString())), (clients) {
      if (clients.isEmpty) {
        emit(const ClientsEmpty());
      } else {
        emit(ClientsLoaded(clients));
      }
    });
  }

  Future<void> _updateClient(
    UpdateClient event,
    Emitter<ClientBlocState> emit,
  ) async {
    emit(ClientLoading());
    final result = await sl<UpdateClientUsecase>().call(event.client);

    await result.fold(
      (failure) async {
        emit(ClientError(failure.toString()));
      },
      (client) async {
        await sl<HiveClientService>().updateItem(event.client);
        emit(ClientUpdated(client)); // ✅ safe emit
      },
    );
  }

  Future<void> _addClient(
    AddClient event,
    Emitter<ClientBlocState> emit,
  ) async {
    emit(ClientLoading());
    final result = await sl<AddClientUsecase>().call(event.client);
    await result.fold(
      (failure) async {
        emit(ClientError(failure.toString()));
      },
      (client) async {
        await sl<HiveClientService>().addItem(event.client);
        emit(ClientAdded(client)); // ✅ safe emit
      },
    );
  }

  Future<void> _onCountClients(
    ClientsCounter event,
    Emitter<ClientBlocState> emit,
  ) async {
    // 1️⃣ Try cache first
    String uid = event.uid;
    final cachedItems = await sl<HiveClientService>().getItems(uid);

    if (cachedItems.isEmpty) {
      emit(ClientsCounted(0));
      return;
    }
    emit(ClientsCounted(cachedItems.length));
  }

  Future<void> _onLoadClientsCacheFirstThenNetwork(
    LoadClientsCacheFirstThenNetwork event,
    Emitter<ClientBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }
    emit(const ClientLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveClientService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(ClientsLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FindClientsUsecase>().call(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(ClientError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (clients) async {
        try {
          if (clients.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const ClientsEmpty());
            }
            return;
          }

          if (cachedItems.toString() != clients.toString()) {
            emit(ClientsLoaded(clients, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveClientService>().insertItems(clients);
          } else {
            // no change
            emit(ClientsLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(ClientError(e.toString()));
        }
      },
    );
  }
}
