import 'dart:core';

import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/outfit_plan_model_hive_type.dart';
import 'package:fashionista/data/models/closet/outfit_closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:fashionista/core/models/hive/hive_type.dart' as hive;

part 'outfit_plan_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.outfitPlanModelHiveType)
class OutfitPlanModel extends Equatable {
  @HiveField(OutfitPlanModelHiveType.uid)
  final String? uid;

  @HiveField(OutfitPlanModelHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @HiveField(OutfitPlanModelHiveType.outfitItem)
  @JsonKey(name: 'outfit_item')
  final OutfitClosetItem outfitItem;

  @JsonKey(name: 'occassion')
  @HiveField(OutfitPlanModelHiveType.occasion)
  final String? occassion;

  @JsonKey(name: 'date')
  @HiveField(OutfitPlanModelHiveType.date)
  final int date;

  @JsonKey(name: 'recurrence_end_date')
  @HiveField(OutfitPlanModelHiveType.recurrenceEndDate)
  final int? recurrenceEndDate;

  @JsonKey(name: 'recurrence')
  @HiveField(OutfitPlanModelHiveType.recurrence)
  final String recurrence;

  @JsonKey(name: 'days_of_week')
  @HiveField(OutfitPlanModelHiveType.daysOfWeek)
  final List<int>? daysOfWeek;

  @JsonKey(name: 'recurrence_count')
  @HiveField(OutfitPlanModelHiveType.recurrenceCount)
  final int? recurrenceCount;

  @JsonKey(name: 'note')
  @HiveField(OutfitPlanModelHiveType.note)
  final String? note;

  const OutfitPlanModel({
    this.uid,
    required this.createdBy,
    required this.outfitItem,
    this.occassion,
    required this.date,
    this.recurrenceEndDate,
    required this.recurrence,
    this.daysOfWeek,
    this.recurrenceCount,
    this.note,
  });

  factory OutfitPlanModel.fromJson(Map<String, dynamic> json) =>
      _$OutfitPlanModelFromJson(json);

  Map<String, dynamic> toJson() => _$OutfitPlanModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    createdBy,
    outfitItem,
    occassion,
    date,
    recurrenceEndDate,
    recurrence,
    daysOfWeek,
    recurrenceCount,
    note,
  ];

  factory OutfitPlanModel.empty() {
    return OutfitPlanModel(
      uid: '',
      createdBy: '',
      outfitItem: OutfitClosetItem.empty(),
      occassion: '',
      date: 0,
      recurrenceEndDate: 0,
      recurrence: '',
      daysOfWeek: [],
      recurrenceCount: 0,
      note: '',
    );
  }

  OutfitPlanModel copyWith({
    String? uid,
    String? createdBy,
    OutfitClosetItem? outfitItem,
    String? occassion,
    int? date,
    int? recurrenceEndDate,
    String? recurrence,
    List<int>? daysOfWeek,
    int? recurrenceCount,
    String? note,
  }) {
    return OutfitPlanModel(
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
      outfitItem: outfitItem ?? this.outfitItem,
      occassion: occassion ?? this.occassion,
      date: date ?? this.date,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrence: recurrence ?? this.recurrence,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
      note: note ?? this.note,
    );
  }
}
