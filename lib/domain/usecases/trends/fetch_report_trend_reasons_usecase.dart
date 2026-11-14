import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';
import 'package:fashionista/domain/repository/trends/report_trend_repository.dart';

class FetchReportTrendReasonsUsecase
    implements Usecase<Either<String, List<ReportTrendReasonModel>>, String> {
  @override
  Future<Either<String, List<ReportTrendReasonModel>>> call(String params) {
    return sl<ReportTrendRepository>().fetchReasons();
  }
}
