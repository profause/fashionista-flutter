import 'package:fashionista/core/models/hive/work_order_status_progress_model_hive_type.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'work_order_status_progress_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.workOrderStatusProgressModel)
class WorkOrderStatusProgressModel extends Equatable {
  @HiveField(WorkOrderStatusProgressModelHiveType.uid)
  final String? uid;

  @HiveField(WorkOrderStatusProgressModelHiveType.status)
  final String status;

  @HiveField(WorkOrderStatusProgressModelHiveType.description)
  final String? description;

  @HiveField(WorkOrderStatusProgressModelHiveType.workOrderId)
  @JsonKey(name: 'work_order_id')
  final String? workOrderId;

  @HiveField(WorkOrderStatusProgressModelHiveType.featuredMedia)
  @JsonKey(name: 'featured_media')
  final List<FeaturedMediaModel>? featuredMedia;

  @HiveField(WorkOrderStatusProgressModelHiveType.createdAt)
  @JsonKey(name: 'created_at')
  final int? createdAt;

  @HiveField(WorkOrderStatusProgressModelHiveType.updatedAt)
  @JsonKey(name: 'updated_at')
  final int? updatedAt;

  @HiveField(WorkOrderStatusProgressModelHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String createdBy;

  const WorkOrderStatusProgressModel({
    this.uid,
    required this.status,
    this.description,
    this.workOrderId,
    this.featuredMedia,
    this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  factory WorkOrderStatusProgressModel.fromJson(Map<String, dynamic> json) =>
      _$WorkOrderStatusProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkOrderStatusProgressModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    status,
    description,
    workOrderId,
    featuredMedia,
    createdAt,
    updatedAt,
    createdBy,
  ];

  WorkOrderStatusProgressModel copyWith({
    String? uid,
    String? status,
    String? description,
    String? workOrderId,
    List<FeaturedMediaModel>? featuredMedia,
    int? createdAt,
    int? updatedAt,
    String? createdBy,
  }) {
    return WorkOrderStatusProgressModel(
      uid: uid ?? this.uid,
      status: status ?? this.status,
      description: description ?? this.description,
      workOrderId: workOrderId ?? this.workOrderId,
      featuredMedia: featuredMedia ?? this.featuredMedia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory WorkOrderStatusProgressModel.empty() {
    return WorkOrderStatusProgressModel(
      uid: '',
      status: '',
      description: '',
      workOrderId: '',
      featuredMedia: [],
      createdAt: 0,
      updatedAt: 0,
      createdBy: '',
    );
  }
}
