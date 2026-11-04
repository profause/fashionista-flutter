// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_closet_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutfitClosetItemAdapter extends TypeAdapter<OutfitClosetItem> {
  @override
  final int typeId = 13;

  @override
  OutfitClosetItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutfitClosetItem(
      uid: fields[0] as String,
      featuredMedia: (fields[1] as List).cast<FeaturedMediaModel>(),
      description: fields[2] as String,
      category: fields[3] as String,
      thumbnailUrl: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitClosetItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.featuredMedia)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.thumbnailUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitClosetItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutfitClosetItem _$OutfitClosetItemFromJson(Map<String, dynamic> json) =>
    OutfitClosetItem(
      uid: json['uid'] as String,
      featuredMedia: (json['featured_media'] as List<dynamic>)
          .map((e) => FeaturedMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String,
      category: json['category'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );

Map<String, dynamic> _$OutfitClosetItemToJson(OutfitClosetItem instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'featured_media': instance.featuredMedia.map((e) => e.toJson()).toList(),
      'description': instance.description,
      'category': instance.category,
      'thumbnail_url': instance.thumbnailUrl,
    };
