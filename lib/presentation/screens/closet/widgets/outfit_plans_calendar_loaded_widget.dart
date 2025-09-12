import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_plan_info_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OutfitPlansCalendarLoadedWidget extends StatelessWidget {
  final Map<DateTime, List<OutfitPlanModel>> outfitPlansByDate;

  const OutfitPlansCalendarLoadedWidget({
    super.key,
    required this.outfitPlansByDate,
  });

  /// Generate all 7 days of the current week (Mon–Sun)
  List<DateTime> _currentWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _currentWeekDays();
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final day = weekDays[index];
        final plans = outfitPlansByDate[DateUtils.dateOnly(day)] ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.E().format(day),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: plans.isNotEmpty
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: plans.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) =>
                            OutfitPlanInfoCardWidget(plan: plans[i]),
                      )
                    : Center(
                        child: Text(
                          "No outfits planned",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
