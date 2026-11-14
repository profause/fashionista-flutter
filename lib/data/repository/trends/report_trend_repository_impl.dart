import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';
import 'package:fashionista/data/models/trends/trend_report_result.dart';
import 'package:fashionista/data/services/firebase/firebase_report_trend_service.dart';
import 'package:fashionista/domain/repository/trends/report_trend_repository.dart';

class ReportTrendRepositoryImpl implements ReportTrendRepository {
  @override
  Future<Either<String, List<ReportTrendReasonModel>>> fetchReasons() {
    return sl<FirebaseReportTrendService>().fetchReasons();
  }

  @override
  Future<Either<String, TrendReportResult>> reportTrend({
    required String trendId,
    required String reasonId,
  }) {
    return sl<FirebaseReportTrendService>().reportTrend(
      trendId: trendId,
      reasonId: reasonId,
    );
  }
}
