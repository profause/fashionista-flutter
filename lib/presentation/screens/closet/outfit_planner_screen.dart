import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_state.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_plan_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OutfitPlannerScreen extends StatefulWidget {
  const OutfitPlannerScreen({super.key});

  @override
  State<OutfitPlannerScreen> createState() => _OutfitPlannerScreenState();
}

class _OutfitPlannerScreenState extends State<OutfitPlannerScreen> {
  late TextEditingController _dateInputController;
  late DateTime _currentDate;
  late DateTime _startOfTheWeek;
  late DateTime _endOfTheWeek; // 👈 keep track of current date
  late List<DateTime> _weekDays;
  Timer? _debounce; // 👈 debounce timer

  @override
  void initState() {
    _dateInputController = TextEditingController();

    // 👇 set initial text
    _currentDate = DateTime.now(); //.add(Duration(days: 7));
    final monday = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );

    _weekDays = List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );

    _startOfTheWeek = _weekDays.first;
    _endOfTheWeek = _weekDays.last;

    _dateInputController.text = DateFormat('yyyy-MM-dd').format(_currentDate);

    // context.read<ClosetOutfitPlannerBloc>().add(
    //   LoadOutfitPlansForCalendar('', _currentDate, _currentDate),
    // );
    _loadPlansForDate(_startOfTheWeek, _endOfTheWeek);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            pinned: true,
            stretch: true,
            expandedHeight: 48,
            toolbarHeight: 10,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    CustomIconButtonRounded(
                      onPressed: () => getPrevWeekFormatted(),
                      iconData: Icons.arrow_left_rounded,
                      icon: Icon(
                        Icons.arrow_left_rounded,
                        color: colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _dateInputController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          hintText: "Select date...",
                          hintStyle: textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: IconButton(
                            onPressed: _pickDate,
                            icon: Icon(Icons.calendar_month_outlined),
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomIconButtonRounded(
                      onPressed: () => getNextWeekFormatted(),
                      iconData: Icons.arrow_right_rounded,
                      icon: Icon(
                        Icons.arrow_right_rounded,
                        color: colorScheme.primary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          BlocBuilder<ClosetOutfitPlannerBloc, ClosetOutfitPlanBlocState>(
            builder: (context, state) {
              switch (state) {
                case OutfitPlanLoading():
                  return const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  );
                case OutfitPlansLoaded(:final outfitPlans):
                  return SliverToBoxAdapter(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(0.0),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: outfitPlans.length,
                      itemBuilder: (context, index) {
                        final plan = outfitPlans[index];
                        return OutfitPlanInfoCardWidget(
                          plan: plan,
                          onTap: () async {
                            //bottom sheet
                          },
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const Divider(height: .1, thickness: .1, indent: 40),
                    ),
                  );
                case OutfitPlansCalendarLoaded(
                  :final outfitPlans,
                  :final fromCache,
                ):
                  // 1️⃣ Flatten and group by date
                  // 1. Normalize outfitPlans keys
                  final grouped = <DateTime, List<OutfitPlanModel>>{};
                  outfitPlans.forEach((k, v) {
                    final day = DateTime(k.year, k.month, k.day); // strip time
                    grouped.putIfAbsent(day, () => []);
                    grouped[day]!.addAll(v);
                  });

                  // 2. Normalize week days too (safety)
                  final normalizedWeekDays = _weekDays
                      .map((d) => DateTime(d.year, d.month, d.day))
                      .toList();

                  // 2️⃣ Get current week (Mon → Sun)

                  // 3️⃣ SliverList to display 7 rows
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final date = normalizedWeekDays[index];
                        final plansForDay = grouped[date] ?? [];

                        final now = DateTime.now();
                        final isToday =
                            date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 👈 Day column
                              SizedBox(
                                width: 55,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.E().format(date), // Mon, Tue
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isToday
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : null,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat.MMMd().format(date), // Jan 10
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isToday
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : null,
                                          ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 👈 Plans
                              Expanded(
                                child: plansForDay.isNotEmpty
                                    ? Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: plansForDay.map((plan) {
                                          return ActionChip(
                                            side: BorderSide.none,
                                            clipBehavior: Clip.antiAlias,
                                            labelPadding: const EdgeInsets.all(0),
                                            padding: const EdgeInsets.all(4),
                                            label: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: SizedBox(
                                                height: 45,
                                                width: 70,
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      plan.thumbnailUrl?.trim() ??
                                                      '',
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      const Center(
                                                        child: SizedBox(
                                                          height: 18,
                                                          width: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const CustomColoredBanner(
                                                            text: '',
                                                          ),
                                                ),
                                              ),
                                            ),
                                            onPressed: () {
                                              // open plan detail
                                            },
                                            backgroundColor: Colors.transparent,
                                            labelStyle: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    : Text(
                                        "No plans",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: normalizedWeekDays.length, // Always 7
                    ),
                  );

                case OutfitPlanError(:final message):
                  return SliverToBoxAdapter(
                    child: Center(child: Text("Error: $message")),
                  );

                default:
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 400,
                      child: Center(
                        child: PageEmptyWidget(
                          title: "You have no item on your planner",
                          subtitle: "Add items to your planner",
                          icon: Icons.calendar_month_outlined,
                          iconSize: 48,
                        ),
                      ),
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }

  void getNextDayFormatted() {
    _currentDate = _currentDate.add(const Duration(days: 1));
    _updateDateFieldAndReload();
  }

  /// Move forward one week and return the days (Mon → Sun)
  void getNextWeekFormatted() {
    _currentDate = _currentDate.add(const Duration(days: 7));

    final monday = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );

    final weekDays = List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
    _startOfTheWeek = weekDays.first;
    _endOfTheWeek = weekDays.last;
    _updateDateFieldAndReload();

    _weekDays = weekDays;
  }

  /// Move backward one week and return the days (Mon → Sun)
  void getPrevWeekFormatted() {
    _currentDate = _currentDate.subtract(const Duration(days: 7));

    final monday = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );

    final weekDays = List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );

    _weekDays = weekDays;
    _startOfTheWeek = weekDays.first;
    _endOfTheWeek = weekDays.last;
    _updateDateFieldAndReload();
  }

  void getPrevDayFormatted() {
    _currentDate = _currentDate.subtract(const Duration(days: 1));
    _updateDateFieldAndReload();
  }

  void _debounceLoadPlans() {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadPlansForDate(_startOfTheWeek, _endOfTheWeek);
    });
  }

  void _loadPlansForDate(DateTime startDate, DateTime endDate) {
    context.read<ClosetOutfitPlannerBloc>().add(
      LoadOutfitPlansForCalendar('', startDate, endDate),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _currentDate) {
      setState(() {
        _currentDate = picked;
        _dateInputController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_currentDate);
      });
      _debounceLoadPlans();
    }
  }

  void _updateDateFieldAndReload() {
    _dateInputController.text = DateFormat('yyyy-MM-dd').format(_currentDate);
    _debounceLoadPlans();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _dateInputController.dispose();
    super.dispose();
  }

  List<DateTime> expandOccurrences(
    OutfitPlanModel plan,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final List<DateTime> dates = [];

    final start = DateTime.fromMillisecondsSinceEpoch(plan.date);
    final until = plan.recurrenceEndDate != null && plan.recurrenceEndDate! > 0
        ? DateTime.fromMillisecondsSinceEpoch(plan.recurrenceEndDate!)
        : rangeEnd;

    DateTime current = start;

    // very simple: just handle daily recurrence as an example
    while (!current.isAfter(until) && !current.isAfter(rangeEnd)) {
      if (!current.isBefore(rangeStart)) {
        dates.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }
}
