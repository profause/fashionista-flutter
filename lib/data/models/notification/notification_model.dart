import 'package:fashionista/core/models/hive/notification_model_hive_type.dart';
import 'package:fashionista/core/utils/firestore_timestamp_converter.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.notificationHiveType)
class NotificationModel extends Equatable {
  @HiveField(NotificationModelHiveType.uid)
  final String? uid;
  @HiveField(NotificationModelHiveType.refId)
  @JsonKey(name: 'ref_id')
  final String? refId;
  @HiveField(NotificationModelHiveType.refType)
  @JsonKey(name: 'ref_type')
  final String? refType;
  @HiveField(NotificationModelHiveType.title)
  final String title;
  @HiveField(NotificationModelHiveType.description)
  final String description;
  @HiveField(NotificationModelHiveType.notificationType)
  @JsonKey(name: 'type')
  final String type;
  @HiveField(NotificationModelHiveType.author)
  final AuthorModel? author;
  @HiveField(NotificationModelHiveType.createdAt)
  @JsonKey(name: 'created_at')
  final int createdAt;
  @HiveField(NotificationModelHiveType.status)
  final String? status;

  /// Fine-grained event (`appointment_confirmed`, `order_status_updated`, ...).
  /// `type` stays the coarse category the inbox renders.
  @HiveField(NotificationModelHiveType.event)
  @JsonKey(name: 'event')
  final String? event;

  /// When the recipient read the notification. `null` while unread.
  @HiveField(NotificationModelHiveType.readAt)
  @FirestoreTimestampConverter()
  @JsonKey(name: 'read_at')
  final DateTime? readAt;

  /// Structured routing data (booking id, designer id, audience, ...).
  @HiveField(NotificationModelHiveType.data)
  @JsonKey(name: 'data')
  final Map<String, String>? data;

  final String? from;
  @HiveField(NotificationModelHiveType.from)
  final String to;
  @HiveField(NotificationModelHiveType.to)
  const NotificationModel({
    this.uid,
    this.refId,
    this.refType,
    required this.title,
    required this.description,
    required this.type,
    this.author,
    this.createdAt = 0,
    this.status,
    this.event,
    this.readAt,
    this.data,
    this.from,
    required this.to,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    refId,
    refType,
    title,
    description,
    type,
    author,
    createdAt,
    status,
    event,
    readAt,
    data,
    from,
    to,
  ];

  NotificationModel copyWith({
    String? uid,
    String? refId,
    String? refType,
    String? title,
    String? description,
    String? type,
    AuthorModel? author,
    int? createdAt,
    String? status,
    String? event,
    DateTime? readAt,
    Map<String, String>? data,
    String? from,
    String? to,
  }) {
    return NotificationModel(
      uid: uid ?? this.uid,
      refId: refId ?? this.refId,
      refType: refType ?? this.refType,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      event: event ?? this.event,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  factory NotificationModel.empty() {
    return NotificationModel(
      uid: '',
      refId: '',
      refType: '',
      title: '',
      description: '',
      type: 'default',
      author: null,
      createdAt: 0,
      status: '',
      event: '',
      readAt: null,
      data: const {},
      from: '',
      to: '',
    );
  }
}

enum NotificationType { like, comment, follow, workOrderRequest, share }
