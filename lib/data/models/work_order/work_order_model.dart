import 'package:fashionista/core/models/hive/work_order_model_hive_type.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'work_order_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.workOrderModelHiveType)
class WorkOrderModel extends Equatable {
  @HiveField(WorkOrderModelHiveType.uid)
  final String? uid;

  @HiveField(WorkOrderModelHiveType.title)
  final String title;

  @HiveField(WorkOrderModelHiveType.description)
  final String? description;

  @HiveField(WorkOrderModelHiveType.status)
  final String? status;

  @HiveField(WorkOrderModelHiveType.workOrderType)
  @JsonKey(name: 'work_order_type')
  final String? workOrderType;

  @HiveField(WorkOrderModelHiveType.featuredMedia)
  @JsonKey(name: 'featured_media')
  final List<FeaturedMediaModel>? featuredMedia;

  @HiveField(WorkOrderModelHiveType.createdAt)
  @JsonKey(name: 'created_at')
  final int? createdAt;

  @HiveField(WorkOrderModelHiveType.updatedAt)
  @JsonKey(name: 'updated_at')
  final int? updatedAt;

  @HiveField(WorkOrderModelHiveType.startDate)
  @JsonKey(name: 'start_date')
  final DateTime? startDate;

  @HiveField(WorkOrderModelHiveType.dueDate)
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;

  @HiveField(WorkOrderModelHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @HiveField(WorkOrderModelHiveType.client)
  @JsonKey(name: 'client')
  final AuthorModel? client;

  @HiveField(WorkOrderModelHiveType.author)
  @JsonKey(name: 'author')
  final AuthorModel? author;

  @HiveField(WorkOrderModelHiveType.isBookmarked)
  @JsonKey(name: 'is_bookmarked')
  final bool? isBookmarked;

  @HiveField(WorkOrderModelHiveType.tags)
  @JsonKey(name: 'tags')
  final String? tags;

  const WorkOrderModel({
    this.uid,
    required this.title,
    this.description,
    this.status,
    this.featuredMedia,
    this.createdAt,
    this.updatedAt,
    this.startDate,
    this.dueDate,
    required this.createdBy,
    this.client,
    this.isBookmarked,
    this.tags,
    this.workOrderType,
    this.author,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) =>
      _$WorkOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkOrderModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    title,
    description,
    status,
    createdAt,
    updatedAt,
    createdBy,
    featuredMedia,
    isBookmarked,
    tags,
    client,
    startDate,
    dueDate,
    workOrderType,
    author,
  ];

  WorkOrderModel copyWith({
    String? uid,
    String? title,
    String? description,
    String? status,
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    List<FeaturedMediaModel>? featuredMedia,
    bool? isBookmarked,
    String? tags,
    AuthorModel? client,
    DateTime? startDate,
    DateTime? dueDate,
    String? workOrderType,
    AuthorModel? author,
  }) {
    return WorkOrderModel(
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      featuredMedia: featuredMedia ?? this.featuredMedia,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      tags: tags ?? this.tags,
      client: client ?? this.client,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      workOrderType: workOrderType ?? this.workOrderType,
      author: author ?? this.author,
    );
  }

  factory WorkOrderModel.empty() {
    return WorkOrderModel(
      uid: '',
      title: '',
      description: '',
      status: '',
      createdAt: 0,
      updatedAt: 0,
      createdBy: '',
      featuredMedia: [],
      isBookmarked: false,
      tags: '',
      client: AuthorModel.empty(),
      startDate: null,
      dueDate: null,
      workOrderType: '',
      author: AuthorModel.empty(),
    );
  }
}
