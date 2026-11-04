import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class DeleteAvailabilityExceptionParams {
  final String designerId;
  final String date;

  const DeleteAvailabilityExceptionParams({
    required this.designerId,
    required this.date,
  });
}

class DeleteAvailabilityExceptionUsecase
    implements Usecase<Either<String, void>, DeleteAvailabilityExceptionParams> {
  @override
  Future<Either<String, void>> call(params) {
    return sl<AvailabilityRepository>().deleteException(
      params.designerId,
      params.date,
    );
  }
}
