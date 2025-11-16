import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_state.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/data/services/hive/hive_outfit_plan_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClosetOutfitPlannerBloc
    extends Bloc<ClosetOutfitPlanBlocEvent, ClosetOutfitPlanBlocState> {
  ClosetOutfitPlannerBloc() : super(const OutfitPlanInitial()) {
    on<LoadOutfitPlans>(_onLoadOutfitPlans);
    on<UpdateOutfitPlan>(_updateOutfitPlan);
    on<DeleteOutfitPlan>(_deleteOutfitPlan);
    on<LoadOutfitPlansCacheFirstThenNetwork>(
      _onLoadOutfitPlansCacheFirstThenNetwork,
    );
    on<LoadOutfitPlansForCalendar>(_onLoadOutfitPlansForCalendar);
    on<ClearOutfitPlan>((event, emit) => emit(const OutfitPlanInitial()));
  }

  Future<void> _onLoadOutfitPlans(
    LoadOutfitPlans event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    emit(const OutfitPlanLoading());

    final result = await sl<FirebaseClosetService>().findOutfitPlans(event.uid);

    result.fold(
      (failure) => emit(OutfitPlanError(failure.toString())),
      (outfit) => emit(OutfitPlansLoaded(outfit)),
    );
  }

  Future<void> _deleteOutfitPlan(
    DeleteOutfitPlan event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    var result = await sl<FirebaseClosetService>().deleteOutfitPlan(
      event.outfitPlanModel,
    );
    result.fold((l) => null, (r) => emit(OutfitPlanDeleted(r)));
  }

  Future<void> _updateOutfitPlan(
    UpdateOutfitPlan event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    emit(OutfitPlanLoading());
    emit(OutfitPlanUpdated(event.outfitPlan));
    //emit(OutfitPlanLoaded(event.outfit));
  }

  Future<void> _onLoadOutfitPlansCacheFirstThenNetwork(
    LoadOutfitPlansCacheFirstThenNetwork event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }

    emit(const OutfitPlanLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveOutfitPlanService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(OutfitPlansLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FirebaseClosetService>().findOutfitPlans(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(OutfitPlanError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (outfitPlans) async {
        try {
          if (outfitPlans.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const OutfitPlansEmpty());
            }
            return;
          }

          if (cachedItems.toString() != outfitPlans.toString()) {
            emit(OutfitPlansLoaded(outfitPlans, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveOutfitPlanService>().insertItems(
              'outfit_plans',
              items: outfitPlans,
            );
          } else {
            // no change
            emit(OutfitPlansLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(OutfitPlanError(e.toString()));
        }
      },
    );
  }

  Future<void> _onLoadOutfitPlansForCalendar(
    LoadOutfitPlansForCalendar event,
    Emitter<ClosetOutfitPlanBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }

    emit(const OutfitPlanLoading());
    final result = await getPlansForCalendar(
      uid,
      event.rangeStart,
      event.rangeEnd,
    );
    if (result.isEmpty) {
      emit(const OutfitPlansEmpty());
      return;
    }
    emit(OutfitPlansCalendarLoaded(result, fromCache: false));
  }

  List<DateTime> expandOccurrences(
  OutfitPlanModel plan,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final List<DateTime> occurrences = [];

  // --- Base date (start of the recurrence) ---
  if (plan.date <= 0) return occurrences;

  DateTime startDate =
      DateTime.fromMillisecondsSinceEpoch(plan.date).toLocal();

  // --- Recurrence end validation ---
  final bool hasValidEnd = plan.recurrenceEndDate != null &&
      plan.recurrenceEndDate! > 0;

  DateTime effectiveEnd = hasValidEnd
      ? DateTime.fromMillisecondsSinceEpoch(plan.recurrenceEndDate!).toLocal()
      : rangeEnd;

  // Prevent negative or backwards ranges
  if (effectiveEnd.isBefore(startDate)) {
    debugPrint("⚠ Invalid recurrence (end < start) for plan ${plan.uid}");
    return occurrences;
  }

  // Prevent runaway loops (safety guard)
  final DateTime hardStop = DateTime.now().add(const Duration(days: 3650));
  if (effectiveEnd.isAfter(hardStop)) effectiveEnd = hardStop;

  // --- Handle recurrence cases ---
  switch (plan.recurrence) {
    case 'none':
      if (!startDate.isBefore(rangeStart) &&
          !startDate.isAfter(rangeEnd)) {
        occurrences.add(startDate);
      }
      break;

    case 'daily':
      {
        final totalDays =
            effectiveEnd.difference(startDate).inDays + 1;

        if (totalDays <= 0) break;

        for (int i = 0; i < totalDays; i++) {
          final date = startDate.add(Duration(days: i));
          if (date.isBefore(rangeStart) || date.isAfter(rangeEnd)) continue;
          occurrences.add(date);
        }
      }
      break;

    case 'weekly':
      {
        final days = plan.daysOfWeek ?? [];

        if (days.isEmpty) {
          debugPrint("⚠ weekly plan has empty daysOfWeek: ${plan.uid}");
          break;
        }

        DateTime cursor = startDate;

        while (!cursor.isAfter(effectiveEnd)) {
          if (!cursor.isBefore(rangeStart) &&
              !cursor.isAfter(rangeEnd) &&
              days.contains(cursor.weekday)) {
            occurrences.add(cursor);
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      }
      break;

    case 'monthly':
      {
        DateTime cursor = startDate;

        while (!cursor.isAfter(effectiveEnd)) {
          if (!cursor.isBefore(rangeStart) &&
              !cursor.isAfter(rangeEnd)) {
            occurrences.add(cursor);
          }

          // Month increment safe (handles overflow)
          cursor = DateTime(cursor.year, cursor.month + 1, cursor.day);
        }
      }
      break;

    case 'yearly':
      {
        DateTime cursor = startDate;

        while (!cursor.isAfter(effectiveEnd)) {
          if (!cursor.isBefore(rangeStart) &&
              !cursor.isAfter(rangeEnd)) {
            occurrences.add(cursor);
          }

          cursor = DateTime(cursor.year + 1, cursor.month, cursor.day);
        }
      }
      break;
  }

  return occurrences;
}


  Future<Map<DateTime, List<OutfitPlanModel>>> getPlansForCalendar(
    String userId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final results = await sl<FirebaseClosetService>().fetchPlansForRange(
      userId,
      rangeStart.millisecondsSinceEpoch,
      rangeEnd.millisecondsSinceEpoch,
    );

    final Map<DateTime, List<OutfitPlanModel>> calendarData = {};

    results.fold(
      (failure) {
        debugPrint("Error loading plans for calendar: $failure");
      },
      (plans) {
        for (final plan in plans) {
          final occurrences = expandOccurrences(plan, rangeStart, rangeEnd);
          for (final date in occurrences) {
            final day = DateTime(date.year, date.month, date.day); // normalize
            calendarData.putIfAbsent(day, () => []).add(plan);
          }
        }
      },
    );
    return calendarData;
  }
}
