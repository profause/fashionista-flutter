import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class FetchDesignerTimezoneUsecase
    implements Usecase<Either<String, String?>, String> {
  @override
  Future<Either<String, String?>> call(params) {
    return sl<AvailabilityRepository>().fetchDesignerTimezone(params);
  }
}
