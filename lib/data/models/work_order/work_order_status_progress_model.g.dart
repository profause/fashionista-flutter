// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_status_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkOrderStatusProgressModelAdapter
    extends TypeAdapter<WorkOrderStatusProgressModel> {
  @override
  final int typeId = 15;

  @override
  WorkOrderStatusProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkOrderStatusProgressModel(
      uid: fields[0] as String?,
      status: fields[1] as String,
      description: fields[2] as String?,
      workOrderId: fields[3] as String?,
      featuredMedia: (fields[7] as List?)?.cast<FeaturedMediaModel>(),
      createdAt: fields[4] as int?,
      updatedAt: fields[5] as int?,
      createdBy: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WorkOrderStatusProgressModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.workOrderId)
      ..writeByte(7)
      ..write(obj.featuredMedia)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkOrderStatusProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderStatusProgressModel _$WorkOrderStatusProgressModelFromJson(
        Map<String, dynamic> json) =>
    WorkOrderStatusProgressModel(
      uid: json['uid'] as String?,
      status: json['status'] as String,
      description: json['description'] as String?,
      workOrderId: json['work_order_id'] as String?,
      featuredMedia: (json['featured_media'] as List<dynamic>?)
          ?.map((e) => FeaturedMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      createdBy: json['created_by'] as String,
    );

Map<String, dynamic> _$WorkOrderStatusProgressModelToJson(
        WorkOrderStatusProgressModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'status': instance.status,
      'description': instance.description,
      'work_order_id': instance.workOrderId,
      'featured_media': instance.featuredMedia?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'created_by': instance.createdBy,
    };
