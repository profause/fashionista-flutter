import 'dart:core';

import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/outfit_plan_model_hive_type.dart';
import 'package:fashionista/data/models/closet/outfit_closet_item_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:fashionista/core/models/hive/hive_type.dart' as hive;

part 'outfit_plan_model.g.dart';

enum RecurrenceType { none, daily, weekly, monthly, yearly }

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

  @JsonKey(name: 'created_at')
  @HiveField(OutfitPlanModelHiveType.createdAt)
  final int? createdAt;

  @JsonKey(name: 'updated_at')
  @HiveField(OutfitPlanModelHiveType.updatedAt)
  final int? updatedAt;

  @JsonKey(name: 'thumbnail_url')
  @HiveField(OutfitPlanModelHiveType.thumbnailUrl)
  final String? thumbnailUrl;

  @JsonKey(name: 'set_reminder')
  @HiveField(OutfitPlanModelHiveType.setReminder)
  final bool? setReminder;

  @JsonKey(name: 'when_to_remind')
  @HiveField(OutfitPlanModelHiveType.whenToRemind)
  final int? whenToRemind;

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
    this.createdAt,
    this.updatedAt,
    this.thumbnailUrl,
    this.setReminder,
    this.whenToRemind,
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
    createdAt,
    updatedAt,
    thumbnailUrl,
    setReminder,
    whenToRemind,
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
      createdAt: 0,
      updatedAt: 0,
      thumbnailUrl: '',
      setReminder: false,
      whenToRemind: 0
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
    int? createdAt,
    int? updatedAt,
    String? thumbnailUrl,
    bool? setReminder,
    int? whenToRemind
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      setReminder: setReminder ?? this.setReminder,
      whenToRemind: whenToRemind ?? this.whenToRemind
    );
  }
}
