import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/domain/repository/clients/clients_repository.dart';

class UpdateClientUsecase implements Usecase<Either, Client>{

  @override
  Future<Either> call(params) {
    return sl<ClientsRepository>().updateClientToFirestore(params);
  }

}