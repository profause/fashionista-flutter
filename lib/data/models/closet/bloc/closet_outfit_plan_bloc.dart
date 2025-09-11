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
      (closetitems) async {
        try {
          if (closetitems.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const OutfitPlansEmpty());
            }
            return;
          }

          if (cachedItems.toString() != closetitems.toString()) {
            emit(OutfitPlansLoaded(closetitems, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveOutfitPlanService>().insertItems(
              'closet_items',
              items: closetitems,
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

    emit(OutfitPlansCalendarLoaded(result, fromCache: false));
  }

  List<DateTime> expandOccurrences(
    OutfitPlanModel plan,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final List<DateTime> occurrences = [];

    // Define cutoff (recurrence end or rangeEnd)
    final until = plan.recurrenceEndDate != null
        ? DateTime.fromMillisecondsSinceEpoch(
                plan.recurrenceEndDate!,
              ).isBefore(rangeEnd)
              ? DateTime.fromMillisecondsSinceEpoch(plan.recurrenceEndDate!)
              : rangeEnd
        : rangeEnd;

    DateTime current = DateTime.fromMillisecondsSinceEpoch(plan.date);

    switch (plan.recurrence) {
      case 'none':
        if (current.isAfter(rangeStart) && current.isBefore(rangeEnd)) {
          occurrences.add(current);
        }
        break;

      case 'daily':
        while (current.isBefore(until)) {
          if (!current.isBefore(rangeStart)) {
            occurrences.add(current);
          }
          current = current.add(const Duration(days: 1));
        }
        break;

      case 'weekly':
        // Repeat each week, but only for selected daysOfWeek
        final days = plan.daysOfWeek ?? [];
        while (current.isBefore(until)) {
          if (!current.isBefore(rangeStart) && days.contains(current.weekday)) {
            occurrences.add(current);
          }
          current = current.add(const Duration(days: 1));
        }
        break;

      case 'monthly':
        while (current.isBefore(until)) {
          if (!current.isBefore(rangeStart)) {
            occurrences.add(current);
          }
          current = DateTime(current.year, current.month + 1, current.day);
        }
        break;

      case 'yearly':
        while (current.isBefore(until)) {
          if (!current.isBefore(rangeStart)) {
            occurrences.add(current);
          }
          current = DateTime(current.year + 1, current.month, current.day);
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
            calendarData.putIfAbsent(day, () => []);
            calendarData[day]!.add(plan);
          }
        }
      },
    );

    return calendarData;
  }
}
