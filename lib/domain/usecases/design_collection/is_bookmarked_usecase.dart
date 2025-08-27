import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/design_collection/design_collection_repository.dart';

class IsBookmarkedUsecase extends Usecase<bool, String> {
  @override
  Future<bool> call(String params) {
    return sl<DesignCollectionRepository>().isBookmarkedDesignCollection(
      params,
    );
  }
}
