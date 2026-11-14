import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';
import 'package:fashionista/data/models/trends/trend_report_result.dart';

abstract class FirebaseReportTrendService {
  /// Active reasons, ordered for the report screen.
  Future<Either<String, List<ReportTrendReasonModel>>> fetchReasons();

  /// Records a report through the `reportTrend` callable.
  Future<Either<String, TrendReportResult>> reportTrend({
    required String trendId,
    required String reasonId,
  });
}

class FirebaseReportTrendServiceImpl implements FirebaseReportTrendService {
  static const String reportCallable = 'reportTrend';

  @override
  Future<Either<String, List<ReportTrendReasonModel>>> fetchReasons() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('report_trend_content')
          .get();

      final reasons =
          snapshot.docs
              .map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['uid'] = doc.id;
                data['updated_at'] = _millis(data['updated_at']);
                return ReportTrendReasonModel.fromJson(data);
              })
              .where(
                (reason) => reason.isEnabled && reason.title.trim().isNotEmpty,
              )
              .toList()
            ..sort((a, b) {
              final byOrder = a.sortOrder.compareTo(b.sortOrder);
              return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
            });

      return Right(reasons);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Could not load report reasons.');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, TrendReportResult>> reportTrend({
    required String trendId,
    required String reasonId,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable(reportCallable)
          .call<Map<String, dynamic>>({
            'trendId': trendId,
            'reasonId': reasonId,
          });

      return Right(TrendReportResult.fromMap(result.data));
    } on FirebaseFunctionsException catch (e) {
      return Left(_messageFor(e));
    } catch (e) {
      return Left(e.toString());
    }
  }

  static int? _millis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    return null;
  }

  static String _messageFor(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in to report this trend.';
      case 'not-found':
        return 'This trend or report reason is no longer available.';
      case 'failed-precondition':
        return e.message ?? 'This trend cannot be reported.';
      case 'resource-exhausted':
        return 'You have submitted too many reports. Please try again later.';
      case 'invalid-argument':
        return 'Please select a valid report reason.';
      default:
        return e.message ?? 'Could not submit your report. Please try again.';
    }
  }
}
