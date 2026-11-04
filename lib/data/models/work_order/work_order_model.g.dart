// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkOrderModelAdapter extends TypeAdapter<WorkOrderModel> {
  @override
  final int typeId = 14;

  @override
  WorkOrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkOrderModel(
      uid: fields[0] as String?,
      title: fields[1] as String,
      description: fields[2] as String?,
      status: fields[3] as String?,
      featuredMedia: (fields[9] as List?)?.cast<FeaturedMediaModel>(),
      createdAt: fields[4] as int?,
      updatedAt: fields[5] as int?,
      startDate: fields[10] as DateTime?,
      dueDate: fields[11] as DateTime?,
      createdBy: fields[6] as String,
      client: fields[8] as AuthorModel?,
      isBookmarked: fields[12] as bool?,
      tags: fields[13] as String?,
      workOrderType: fields[7] as String?,
      author: fields[14] as AuthorModel?,
      measurements: (fields[15] as List?)?.cast<ClientMeasurement>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkOrderModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.workOrderType)
      ..writeByte(9)
      ..write(obj.featuredMedia)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.startDate)
      ..writeByte(11)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.client)
      ..writeByte(14)
      ..write(obj.author)
      ..writeByte(12)
      ..write(obj.isBookmarked)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(15)
      ..write(obj.measurements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkOrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderModel _$WorkOrderModelFromJson(Map<String, dynamic> json) =>
    WorkOrderModel(
      uid: json['uid'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String?,
      featuredMedia: (json['featured_media'] as List<dynamic>?)
          ?.map((e) => FeaturedMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      createdBy: json['created_by'] as String,
      client: json['client'] == null
          ? null
          : AuthorModel.fromJson(json['client'] as Map<String, dynamic>),
      isBookmarked: json['is_bookmarked'] as bool?,
      tags: json['tags'] as String?,
      workOrderType: json['work_order_type'] as String?,
      author: json['author'] == null
          ? null
          : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      measurements: (json['measurements'] as List<dynamic>?)
              ?.map(
                  (e) => ClientMeasurement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkOrderModelToJson(WorkOrderModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'work_order_type': instance.workOrderType,
      'featured_media': instance.featuredMedia?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'start_date': instance.startDate?.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'created_by': instance.createdBy,
      'client': instance.client?.toJson(),
      'author': instance.author?.toJson(),
      'is_bookmarked': instance.isBookmarked,
      'tags': instance.tags,
      'measurements': instance.measurements?.map((e) => e.toJson()).toList(),
    };
