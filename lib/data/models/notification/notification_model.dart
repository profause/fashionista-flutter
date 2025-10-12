import 'package:fashionista/core/models/hive/notification_model_hive_type.dart';
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
  @JsonKey(name: 'notification_type')
  final NotificationType notificationType;
  @HiveField(NotificationModelHiveType.author)
  final AuthorModel? author;
  @HiveField(NotificationModelHiveType.createdAt)
  @JsonKey(name: 'created_at')
  final int createdAt;
  @HiveField(NotificationModelHiveType.status)
  final String? status;

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
    required this.notificationType,
    this.author,
    this.createdAt = 0,
    this.status,
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
    notificationType,
    author,
    createdAt,
    status,
    from,
    to,
  ];

  NotificationModel copyWith({
    String? uid,
    String? refId,
    String? refType,
    String? title,
    String? description,
    NotificationType? notificationType,
    AuthorModel? author,
    int? createdAt,
    String? status,
    String? from,
    String? to,
  }) {
    return NotificationModel(
      uid: uid ?? this.uid,
      refId: refId ?? this.refId,
      refType: refType ?? this.refType,
      title: title ?? this.title,
      description: description ?? this.description,
      notificationType: notificationType ?? this.notificationType,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
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
      notificationType: NotificationType.like,
      author: null,
      createdAt: 0,
      status: '',
      from: '',
      to: '',
    );
  }
}

enum NotificationType { like, comment, follow, workOrderRequest, share }
