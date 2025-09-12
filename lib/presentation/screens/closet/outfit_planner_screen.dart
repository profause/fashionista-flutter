import 'dart:async';

import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_state.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_plan_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

class OutfitPlannerScreen extends StatefulWidget {
  const OutfitPlannerScreen({super.key});

  @override
  State<OutfitPlannerScreen> createState() => _OutfitPlannerScreenState();
}

class _OutfitPlannerScreenState extends State<OutfitPlannerScreen> {
  late TextEditingController _dateInputController;
  late DateTime _currentDate; // 👈 keep track of current date
  Timer? _debounce; // 👈 debounce timer

  @override
  void initState() {
    _dateInputController = TextEditingController();

    // 👇 set initial text
    _currentDate = DateTime.now().add(Duration(days: 7));
    _dateInputController.text = DateFormat('yyyy-MM-dd').format(_currentDate);

    // context.read<ClosetOutfitPlannerBloc>().add(
    //   LoadOutfitPlansForCalendar('', _currentDate, _currentDate),
    // );
    _loadPlansForDate(_currentDate);
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
                      onPressed: () => getPrevDayFormatted(),
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
                      onPressed: () => getNextDayFormatted(),
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
                  final grouped = <DateTime, List<OutfitPlanModel>>{};
                  for (final plan in outfitPlans.values.expand((e) => e)) {
                    final date = DateTime.fromMillisecondsSinceEpoch(plan.date);
                    final key = DateTime(date.year, date.month, date.day);
                    grouped.putIfAbsent(key, () => []).add(plan);
                  }

                  // 2️⃣ Get current week (Mon → Sun)
                  final now = DateTime.now();
                  final monday = now.subtract(
                    Duration(days: now.weekday - 1),
                  ); // start of week
                  final weekDays = List.generate(
                    7,
                    (i) => DateTime(monday.year, monday.month, monday.day + i),
                  );

                  // 3️⃣ SliverList to display 7 rows
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final date = weekDays[index];
                        final plans = grouped[date] ?? [];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 👈 Day of week + date
                              SizedBox(
                                width: 55,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.E().format(
                                        date,
                                      ), // Mon, Tue, Wed
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      DateFormat.MMMd().format(date), // Jan 10
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 👈 Outfit plans in a horizontal row
                              Expanded(
                                child: plans.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: SizedBox(
                                          // 👇 let ListView take only as much height as its children
                                          height: plans
                                              .map(
                                                (p) => 140.0,
                                              ) // card height from OutfitPlanInfoCardWidget
                                              .fold<double>(
                                                0,
                                                (max, h) => h > max ? h : max,
                                              ),
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            physics:
                                                const ClampingScrollPhysics(),
                                            itemCount: plans.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 8),
                                            itemBuilder: (context, i) {
                                              final plan = plans[i];
                                              return OutfitPlanInfoCardWidget(
                                                plan: plan,
                                                onTap: () {},
                                              );
                                            },
                                          ),
                                        ),
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
                      childCount: weekDays.length, // Always 7
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
    _currentDate = _currentDate.add(const Duration(days: 7));
    _updateDateFieldAndReload();
  }

  void getPrevDayFormatted() {
    _currentDate = _currentDate.subtract(const Duration(days: 7));
    _updateDateFieldAndReload();
  }

  void _debounceLoadPlans() {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadPlansForDate(_currentDate);
    });
  }

  void _loadPlansForDate(DateTime date) {
    context.read<ClosetOutfitPlannerBloc>().add(
      LoadOutfitPlansForCalendar(
        '',
        date.subtract(const Duration(days: 7)),
        date,
      ),
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
}
