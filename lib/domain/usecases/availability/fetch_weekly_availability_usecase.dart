import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class FetchWeeklyAvailabilityUsecase
    implements Usecase<Either<String, List<DesignerAvailability>>, String> {
  @override
  Future<Either<String, List<DesignerAvailability>>> call(params) {
    return sl<AvailabilityRepository>().fetchWeeklyAvailability(params);
  }
}
