import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class SaveDesignerTimezoneParams {
  final String designerId;
  final String timezone;

  const SaveDesignerTimezoneParams({
    required this.designerId,
    required this.timezone,
  });
}

class SaveDesignerTimezoneUsecase
    implements Usecase<Either<String, void>, SaveDesignerTimezoneParams> {
  @override
  Future<Either<String, void>> call(params) {
    return sl<AvailabilityRepository>().saveDesignerTimezone(
      params.designerId,
      params.timezone,
    );
  }
}
