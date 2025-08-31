import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/clients/clients_repository.dart';

class IsPinnedClientUsecase implements Usecase<bool, String> {
  @override
  Future<bool> call(params) {
    return sl<ClientsRepository>().isPinnedClient(params);
  }
}
