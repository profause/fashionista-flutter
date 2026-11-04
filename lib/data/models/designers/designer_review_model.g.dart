// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designer_review_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DesignerReviewModelAdapter extends TypeAdapter<DesignerReviewModel> {
  @override
  final int typeId = 16;

  @override
  DesignerReviewModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DesignerReviewModel(
      uid: fields[0] as String?,
      createdAt: fields[2] as int?,
      comment: fields[3] as CommentModel,
      rating: fields[1] as int?,
      refId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DesignerReviewModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.comment)
      ..writeByte(1)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.refId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesignerReviewModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignerReviewModel _$DesignerReviewModelFromJson(Map<String, dynamic> json) =>
    DesignerReviewModel(
      uid: json['uid'] as String?,
      createdAt: (json['created_at'] as num?)?.toInt(),
      comment: CommentModel.fromJson(json['comment'] as Map<String, dynamic>),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      refId: json['ref_id'] as String? ?? '',
    );

Map<String, dynamic> _$DesignerReviewModelToJson(
        DesignerReviewModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'created_at': instance.createdAt,
      'comment': instance.comment.toJson(),
      'rating': instance.rating,
      'ref_id': instance.refId,
    };
