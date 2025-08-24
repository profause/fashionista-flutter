import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/designers/designers_repository.dart';

class IsFavouriteUsecase implements Usecase<bool, String> {
  @override
  Future<bool> call(String params) {
    return sl<DesignersRepository>().isFavouriteDesigner(params);
  }
}
