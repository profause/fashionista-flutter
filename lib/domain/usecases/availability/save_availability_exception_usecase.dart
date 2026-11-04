import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class SaveAvailabilityExceptionParams {
  final String designerId;
  final AvailabilityException exception;

  const SaveAvailabilityExceptionParams({
    required this.designerId,
    required this.exception,
  });
}

class SaveAvailabilityExceptionUsecase
    implements Usecase<Either<String, void>, SaveAvailabilityExceptionParams> {
  @override
  Future<Either<String, void>> call(params) {
    return sl<AvailabilityRepository>().saveException(
      params.designerId,
      params.exception,
    );
  }
}
