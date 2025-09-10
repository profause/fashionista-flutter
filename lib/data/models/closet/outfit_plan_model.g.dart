// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutfitPlanModelAdapter extends TypeAdapter<OutfitPlanModel> {
  @override
  final int typeId = 12;

  @override
  OutfitPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutfitPlanModel(
      uid: fields[0] as String?,
      createdBy: fields[6] as String,
      outfitItem: fields[1] as OutfitClosetItem,
      occassion: fields[4] as String?,
      date: fields[2] as int,
      recurrenceEndDate: fields[9] as int?,
      recurrence: fields[3] as String,
      daysOfWeek: (fields[5] as List?)?.cast<int>(),
      recurrenceCount: fields[10] as int?,
      note: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitPlanModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(6)
      ..write(obj.createdBy)
      ..writeByte(1)
      ..write(obj.outfitItem)
      ..writeByte(4)
      ..write(obj.occassion)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(9)
      ..write(obj.recurrenceEndDate)
      ..writeByte(3)
      ..write(obj.recurrence)
      ..writeByte(5)
      ..write(obj.daysOfWeek)
      ..writeByte(10)
      ..write(obj.recurrenceCount)
      ..writeByte(11)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitPlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutfitPlanModel _$OutfitPlanModelFromJson(Map<String, dynamic> json) =>
    OutfitPlanModel(
      uid: json['uid'] as String?,
      createdBy: json['created_by'] as String,
      outfitItem: OutfitClosetItem.fromJson(
          json['outfit_item'] as Map<String, dynamic>),
      occassion: json['occassion'] as String?,
      date: (json['date'] as num).toInt(),
      recurrenceEndDate: (json['recurrence_end_date'] as num?)?.toInt(),
      recurrence: json['recurrence'] as String,
      daysOfWeek: (json['days_of_week'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      recurrenceCount: (json['recurrence_count'] as num?)?.toInt(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$OutfitPlanModelToJson(OutfitPlanModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'created_by': instance.createdBy,
      'outfit_item': instance.outfitItem.toJson(),
      'occassion': instance.occassion,
      'date': instance.date,
      'recurrence_end_date': instance.recurrenceEndDate,
      'recurrence': instance.recurrence,
      'days_of_week': instance.daysOfWeek,
      'recurrence_count': instance.recurrenceCount,
      'note': instance.note,
    };
