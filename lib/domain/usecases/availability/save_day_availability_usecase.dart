import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class SaveDayAvailabilityParams {
  final String designerId;
  final DesignerAvailability availability;

  const SaveDayAvailabilityParams({
    required this.designerId,
    required this.availability,
  });
}

class SaveDayAvailabilityUsecase
    implements Usecase<Either<String, void>, SaveDayAvailabilityParams> {
  @override
  Future<Either<String, void>> call(params) {
    return sl<AvailabilityRepository>().saveDayAvailability(
      params.designerId,
      params.availability,
    );
  }
}
