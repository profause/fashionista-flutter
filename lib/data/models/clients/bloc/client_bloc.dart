import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/domain/usecases/clients/delete_client_usecase.dart';
import 'package:fashionista/domain/usecases/clients/find_client_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/clients/find_clients_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientBloc extends Bloc<ClientBlocEvent, ClientBlocState> {
  ClientBloc() : super(const ClientInitial()) {
    on<LoadClient>(_onLoadClient);
    on<LoadClients>(_onLoadClients);
    on<UpdateClient>(_updateClient);
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

    final result = await sl<FindClientByIdUsecase>().call(event.uid);

    result.fold(
      (failure) => emit(ClientError(failure.toString())),
      (client) => emit(ClientLoaded(client)),
    );
  }

  Future<void> _deleteClient(
    DeleteClient event,
    Emitter<ClientBlocState> emit,
  ) async {
    var result = await sl<DeleteClientUsecase>().call(event.uid);
    result.fold((l) => null, (r) => emit(ClientDeleted(r)));
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
    emit(ClientUpdated(event.client));
    //emit(ClientLoaded(event.client));
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

          // 3️⃣ Detect if data has changed
          // int? cachedFirstTimestamp = cachedItems.isNotEmpty
          //     ? cachedItems.first.createdDate!.millisecondsSinceEpoch
          //     : null;

          // int freshFirstTimestamp =
          //     clients.first.createdDate!.millisecondsSinceEpoch;

          // if (cachedFirstTimestamp == null ||
          //     cachedFirstTimestamp != freshFirstTimestamp) {
          //   emit(ClientsLoaded(clients, fromCache: false));
          //   // 4️⃣ Update cache and emit fresh data
          //   await sl<HiveClientService>().insertItems(
          //     uid,
          //     items: clients,
          //   );
          //   debugPrint('Clients updated');
          //   // emit(
          //   //   ClientsNewData(clients),
          //   // ); // optional "new data" state
          //   // 🔑 Do NOT call `on<Event>` here again!
          // }

          if (cachedItems.toString() != clients.toString()) {
            emit(ClientsLoaded(clients, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveClientService>().insertItems(uid, items: clients);
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
