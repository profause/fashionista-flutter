import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/trends/trend_report_result.dart';
import 'package:fashionista/domain/repository/trends/report_trend_repository.dart';

class SubmitTrendReportParams {
  final String trendId;
  final String reasonId;

  const SubmitTrendReportParams({
    required this.trendId,
    required this.reasonId,
  });
}

class SubmitTrendReportUsecase
    implements
        Usecase<Either<String, TrendReportResult>, SubmitTrendReportParams> {
  @override
  Future<Either<String, TrendReportResult>> call(
    SubmitTrendReportParams params,
  ) {
    return sl<ReportTrendRepository>().reportTrend(
      trendId: params.trendId,
      reasonId: params.reasonId,
    );
  }
}
