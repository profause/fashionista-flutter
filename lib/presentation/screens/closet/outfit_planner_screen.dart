import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
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
  late DateTime _currentDate;
  late DateTime _startOfTheWeek;
  late DateTime _endOfTheWeek; // 👈 keep track of current date
  late List<DateTime> _weekDays;
  Timer? _debounce; // 👈 debounce timer

  @override
  void initState() {
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

    // context.read<ClosetOutfitPlannerBloc>().add(
    //   LoadOutfitPlansForCalendar('', _currentDate, _currentDate),
    // );
    _loadPlansForDate(_startOfTheWeek, _endOfTheWeek);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      pushPinnedChildren: true,
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        // Week selector pill
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: context.cardSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.hairline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => getPrevWeekFormatted(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: context.secondaryLabel,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(999),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 20,
                            color: context.accent,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _weekLabel,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.onCanvasText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => getNextWeekFormatted(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: context.secondaryLabel,
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
              case OutfitPlansCalendarLoaded(:final outfitPlans):
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

                      return _PlannerDayCard(
                        date: date,
                        plans: plansForDay,
                        isToday: isToday,
                        onPlanTap: (plan) => _showDetailsBottomSheet(
                          context,
                          plan,
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
          child: Container(color: context.canvasBackground),
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
        final monday = _currentDate.subtract(
          Duration(days: _currentDate.weekday - 1),
        );
        _weekDays = List.generate(
          7,
          (i) => DateTime(monday.year, monday.month, monday.day + i),
        );
        _startOfTheWeek = _weekDays.first;
        _endOfTheWeek = _weekDays.last;
      });
      _debounceLoadPlans();
    }
  }

  void _updateDateFieldAndReload() {
    setState(() {});
    _debounceLoadPlans();
  }

  /// "August 10 – August 16, 2026"
  String get _weekLabel {
    final start = DateFormat('MMMM d').format(_startOfTheWeek);
    final end = DateFormat('MMMM d, yyyy').format(_endOfTheWeek);
    return '$start – $end';
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

    if (!context.mounted) return;

    //final thumbnailUrl = outfitPlan.thumbnailUrl ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        height: 6,
                        width: 36,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: context.softBorder,
                          borderRadius: BorderRadius.circular(3),
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
                                      onPressed: () {
                                        Navigator.of(ctx).pop(true);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
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
                              side: BorderSide(
                                color: context.hairline,
                              ), // ✅ hairline border
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
      showLoadingDialog(context);

      // CloudinaryConfig config = CloudinaryConfig.fromUri(
      //   appConfig.get('cloudinary_url'),
      // );
      // final cloudinary = Cloudinary.fromConfiguration(config);
      // DestroyParams destroyParams = DestroyParams(publicId: '');
      // await cloudinary.uploader().destroy(destroyParams);
      
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
      dismissLoadingDialog(context);
      Navigator.of(context).pop(false);
      _updateDateFieldAndReload();
      //context.read<ClosetItemBloc>().add(DeleteClosetItem(closetItem));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// One calendar day row (design: white/hairline card, day column + divider,
/// dashed "Schedule an Outfit" empty state or a compact plan row).
class _PlannerDayCard extends StatelessWidget {
  final DateTime date;
  final List<OutfitPlanModel> plans;
  final bool isToday;
  final void Function(OutfitPlanModel plan) onPlanTap;

  const _PlannerDayCard({
    required this.date,
    required this.plans,
    required this.isToday,
    required this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final borderColor = isToday ? accent : context.hairline;
    final dividerColor = isToday
        ? accent.withValues(alpha: 0.3)
        : context.hairline;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isToday ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? accent.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isToday ? 16 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day column
          SizedBox(
            width: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('E').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isToday ? accent : context.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: context.onCanvasText,
                  ),
                ),
                SizedBox(
                  height: 6,
                  child: isToday
                      ? Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 44, color: dividerColor),
          const SizedBox(width: 14),
          Expanded(
            child: plans.isEmpty ? _buildEmpty(context) : _buildPlans(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: context.canvasBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.softBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.mutedText, width: 1.5),
            ),
            child: Center(
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: context.mutedText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Schedule an Outfit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildPlanRow(context, plans[i]),
        ],
      ],
    );
  }

  Widget _buildPlanRow(BuildContext context, OutfitPlanModel plan) {
    final occasion = (plan.occassion?.trim().isNotEmpty ?? false)
        ? plan.occassion!.trim()
        : 'Outfit Fit';
    final timeStr = DateFormat('hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(plan.date),
    );

    return InkWell(
      onTap: () => onPlanTap(plan),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildThumb(context, plan),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              occasion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.onCanvasText,
                              ),
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: context.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isToday
                                ? Icons.schedule
                                : Icons.circle,
                            size: isToday ? 12 : 6,
                            color: isToday
                                ? context.accent
                                : context.accent.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: isToday ? 4 : 6),
                          Flexible(
                            child: Text(
                              timeStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isToday
                                    ? context.accent
                                    : context.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => onPlanTap(plan),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.more_vert,
              size: 18,
              color: context.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(BuildContext context, OutfitPlanModel plan) {
    List<FeaturedMediaModel> media = List.of(plan.outfitItem.featuredMedia);
    final thumb = plan.thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      media = [
        FeaturedMediaModel(aspectRatio: 1, url: thumb, type: 'image'),
      ];
    }
    final items = media.take(4).toList();
    final count = items.length;

    final divider = Container(width: 1, color: context.hairline);
    final dividerH = Container(height: 1, color: context.hairline);

    Widget cell(int i) => _thumbImage(items[i]);

    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.iconSubstrate,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.hairline),
      ),
      child: count == 0
          ? const SizedBox.shrink()
          : count == 1
              ? cell(0)
              : count == 2
                  ? Row(children: [
                      Expanded(child: cell(0)),
                      divider,
                      Expanded(child: cell(1)),
                    ])
                  : count == 3
                      ? Row(children: [
                          Expanded(child: cell(0)),
                          divider,
                          Expanded(
                            child: Column(children: [
                              Expanded(child: cell(1)),
                              dividerH,
                              Expanded(child: cell(2)),
                            ]),
                          ),
                        ])
                      : Column(children: [
                          Expanded(
                            child: Row(children: [
                              Expanded(child: cell(0)),
                              divider,
                              Expanded(child: cell(1)),
                            ]),
                          ),
                          dividerH,
                          Expanded(
                            child: Row(children: [
                              Expanded(child: cell(2)),
                              divider,
                              Expanded(child: cell(3)),
                            ]),
                          ),
                        ]),
    );
  }

  Widget _thumbImage(FeaturedMediaModel preview) {
    return CachedNetworkImage(
      imageUrl: preview.url?.trim() ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => const CustomColoredBanner(
        text: '',
      ),
    );
  }
}
