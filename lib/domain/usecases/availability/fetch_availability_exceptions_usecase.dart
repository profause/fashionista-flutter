import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class FetchAvailabilityExceptionsParams {
  final String designerId;
  final String dateFrom;
  final String dateTo;

  const FetchAvailabilityExceptionsParams({
    required this.designerId,
    required this.dateFrom,
    required this.dateTo,
  });
}

class FetchAvailabilityExceptionsUsecase
    implements
        Usecase<
          Either<String, List<AvailabilityException>>,
          FetchAvailabilityExceptionsParams
        > {
  @override
  Future<Either<String, List<AvailabilityException>>> call(params) {
    return sl<AvailabilityRepository>().fetchExceptions(
      params.designerId,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
    );
  }
}
