import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';
import 'package:fashionista/data/models/trends/trend_report_result.dart';

abstract class ReportTrendRepository {
  Future<Either<String, List<ReportTrendReasonModel>>> fetchReasons();

  Future<Either<String, TrendReportResult>> reportTrend({
    required String trendId,
    required String reasonId,
  });
}
