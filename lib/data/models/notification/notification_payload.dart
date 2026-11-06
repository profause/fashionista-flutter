import 'package:equatable/equatable.dart';

/// A parsed push payload.
///
/// FCM only transports string values, so everything arrives as `Map<String,
/// String>`; this class normalises it once for the router and the inbox.
class NotificationPayload extends Equatable {
  /// Coarse category used by the inbox to pick a widget
  /// (`booking`, `work_order_status_progress`, `measurement`, `info`, ...).
  final String type;

  /// Fine-grained event (`appointment_requested`, `appointment_confirmed`, ...).
  final String event;

  /// id of the resource the notification points at.
  final String refId;

  final String refType;

  /// Who should act on it: `designer` or `client`.
  final String audience;

  /// The designer the notification belongs to, when relevant.
  final String designerId;

  final String title;
  final String body;

  /// Raw data, preserved for diagnostics and future fields.
  final Map<String, String> data;

  const NotificationPayload({
    this.type = '',
    this.event = '',
    this.refId = '',
    this.refType = '',
    this.audience = '',
    this.designerId = '',
    this.title = '',
    this.body = '',
    this.data = const {},
  });

  static const NotificationPayload empty = NotificationPayload();

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    return NotificationPayload(
      type: read(['type']),
      event: read(['event']),
      refId: read(['ref_id', 'refId', 'booking_id', 'work_order_id']),
      refType: read(['ref_type', 'refType']),
      audience: read(['audience', 'recipient_role']),
      designerId: read(['designer_id', 'designerId']),
      title: read(['title']),
      body: read(['body', 'description']),
      data: data.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    );
  }

  bool get isAppointment =>
      type == 'appointment' ||
      // Legacy value on notifications sent before the rename.
      type == 'booking' ||
      refType == 'booking' ||
      event.startsWith('appointment');

  bool get isWorkOrder =>
      type == 'work_order_status_progress' ||
      type == 'workOrderRequest' ||
      refType == 'work_order' ||
      refType == 'work_order_status_progress' ||
      event.startsWith('order_');

  bool get isMeasurement =>
      type == 'measurement' ||
      refType == 'measurement' ||
      event.startsWith('measurement');

  /// A like (or other interaction) on the user's own trend.
  bool get isTrend =>
      type == 'trend' || refType == 'trend' || event.startsWith('trend_');

  /// A review left on the user's designer profile.
  bool get isReview =>
      type == 'review' || refType == 'designer_review' || refType == 'review';

  /// A designer linked the user to one of their client records.
  bool get isClientLinked =>
      type == 'client' || refType == 'client' || event == 'client_linked';

  bool get isForDesigner => audience == 'designer';

  @override
  List<Object?> get props => [
    type,
    event,
    refId,
    refType,
    audience,
    designerId,
    title,
    body,
  ];
}
