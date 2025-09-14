import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_state.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/data/services/hive/hive_outfit_service.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_plan_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:sliver_tools/sliver_tools.dart';

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
    return MultiSliver(
      pushPinnedChildren: true,
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverAppBar(
          backgroundColor: colorScheme.surface,
          pinned: true,
          stretch: true,
          expandedHeight: 30,
          toolbarHeight: 5,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  CustomIconButtonRounded(
                    backgroundColor: colorScheme.surfaceContainerHighest,
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
                    backgroundColor: colorScheme.surfaceContainerHighest,
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

        // background filler
        BlocBuilder<ClosetOutfitPlannerBloc, ClosetOutfitPlanBlocState>(
          builder: (context, state) {
            switch (state) {
              case OutfitPlanLoading():
                return const SliverFillRemaining(
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

                      return Container(
                        color: colorScheme.onPrimary,
                        child: Padding(
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
                                    // if (isToday) ...[
                                    //   const SizedBox(height: 4),
                                    //   Container(
                                    //     width: 6,
                                    //     height: 6,
                                    //     decoration: BoxDecoration(
                                    //       color: Theme.of(
                                    //         context,
                                    //       ).colorScheme.primary,
                                    //       shape: BoxShape.circle,
                                    //     ),
                                    //   ),
                                    // ],
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
                                            labelPadding: const EdgeInsets.all(
                                              0,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            label: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: SizedBox(
                                                height: 45,
                                                width: 70,
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      plan.thumbnailUrl
                                                          ?.trim() ??
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
                                              _showDetailsBottomSheet(
                                                context,
                                                plan,
                                              );
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
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(color: colorScheme.onPrimary),
        ),
      ],
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

  void _showDetailsBottomSheet(
    BuildContext context,
    OutfitPlanModel outfitPlan,
  ) async {
    final random = Random();
    List<FeaturedMediaModel> featuredMedia =
        outfitPlan.outfitItem.featuredMedia;
    final OutfitModel outfit = await sl<HiveOutfitService>().getItem(
      '',
      outfitPlan.outfitItem.uid,
    );

    final thumbnailUrl = outfitPlan.thumbnailUrl ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7, // how tall it opens initially
          minChildSize: 0.7,
          maxChildSize: 0.9,
          shouldCloseOnMinExtent: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Handle bar
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    //const SizedBox(height: 8),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MasonryGridView.builder(
                        padding: const EdgeInsets.all(0),
                        shrinkWrap:
                            true, // ✅ important when inside SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // ✅ let parent handle scroll
                        cacheExtent: 10,
                        gridDelegate:
                            SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: featuredMedia.length > 4 ? 3 : 2,
                            ),
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        itemCount: featuredMedia.length,
                        itemBuilder: (context, index) {
                          final preview = featuredMedia[index];
                          // 👇 Assign different aspect ratios randomly for variety
                          final aspectRatioOptions = [1 / 1];
                          final aspectRatio =
                              aspectRatioOptions[random.nextInt(
                                aspectRatioOptions.length,
                              )];
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: CachedNetworkImage(
                                imageUrl: preview.url!.isEmpty
                                    ? ''
                                    : preview.url!.trim(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return const CustomColoredBanner(text: '');
                                },
                                errorListener: (value) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                outfit.occassion,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // CustomIconButtonRounded(
                            //   iconData: Icons.favorite_outline,
                            //   size: 24,
                            //   onPressed: () => addOrRemoveFromFavourite(outfit),
                            //   icon: AnimatedSwitcher(
                            //     duration: const Duration(milliseconds: 200),
                            //     child: Icon(
                            //       outfit.isFavourite!
                            //           ? Icons.favorite
                            //           : Icons.favorite_outline,
                            //       key: ValueKey(outfit.isFavourite!),
                            //       color: outfit.isFavourite!
                            //           ? Colors.red
                            //           : Colors.grey,
                            //       size: 24,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   outfit.occassion,
                        //   style: Theme.of(context).textTheme.bodySmall,
                        //   maxLines: 1,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6, // 👈 reduced padding
                      children: outfit.tags!.isEmpty
                          ? [SizedBox(height: 1)]
                          : outfit.tags!
                                .split('|')
                                .where(
                                  (tag) => tag.trim().isNotEmpty,
                                ) // ✅ only keep non-empty tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final canDelete = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Item'),
                                  content: const Text(
                                    'Are you sure you want to delete this item?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (canDelete == true) {
                                _deleteOutfitPlan(outfitPlan);
                              }
                            },
                            icon: const Icon(Icons.remove, size: 18),
                            label: const Text("remove from planner"),
                            style: OutlinedButton.styleFrom(
                              elevation: 0, // ✅ no elevation
                              side: const BorderSide(
                                color: Colors.grey,
                              ), // ✅ grey border
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ), // optional: rounded edges
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteOutfitPlan(OutfitPlanModel outfitPlan) async {
    try {
      // create a dynamic list of futures
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final List<Future<dartz.Either>> futures = [];
      futures.add(
        sl<FirebaseClosetService>().deleteClosetItemImage(
          outfitPlan.thumbnailUrl!,
        ),
      );

      // also add delete by id
      futures.add(sl<FirebaseClosetService>().deleteOutfitPlan(outfitPlan));

      // wait for all and capture results
      final results = await Future.wait(futures);

      // handle each result
      for (final result in results) {
        result.fold(
          (failure) {
            // handle failure
            debugPrint("Delete failed: $failure");
          },
          (success) {
            // handle success
            debugPrint("Delete success: $success");
          },
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      _updateDateFieldAndReload();
      //context.read<ClosetItemBloc>().add(DeleteClosetItem(closetItem));
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }
}
