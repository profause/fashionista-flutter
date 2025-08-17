import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/domain/usecases/clients/delete_client_usecase.dart';
import 'package:fashionista/domain/usecases/clients/find_client_by_id_usecase.dart';
import 'package:fashionista/domain/usecases/clients/update_client_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientCubit extends Cubit<ClientState> {
  ClientCubit() : super(ClientInitial());
  void clientUpdated(Client client) async {
    var result = await sl<UpdateClientUsecase>().call(client);
    result.fold((l) => (), (r) => emit(ClientUpdated(client: r)));
  } // emit(clientState);

  void clientDelete(String clientId) async {
    var result = await sl<DeleteClientUsecase>().call(clientId);
    result.fold((l) => null, (r) => emit(ClientDelete(message: r)));
  }

  void clientLoaded(String clientId) async {
    var result = await sl<FindClientByIdUsecase>().call(clientId);
    result.fold((l) => null, (r) => emit(ClientLoaded(client: r)));
  }
}
