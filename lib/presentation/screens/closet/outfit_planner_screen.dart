import 'dart:async';

import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc_state.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_plan_info_card_widget.dart';
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
  late DateTime _currentDate; // 👈 keep track of current date
  Timer? _debounce; // 👈 debounce timer

  @override
  void initState() {
    _dateInputController = TextEditingController();

    // 👇 set initial text
    _currentDate = DateTime.now();
    _dateInputController.text = DateFormat('yyyy-MM-dd').format(_currentDate);

    context.read<ClosetOutfitPlannerBloc>().add(
      LoadOutfitPlansForCalendar('', _currentDate, _currentDate),
    );
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

  void getPrevDayFormatted() {
    _currentDate = _currentDate.subtract(const Duration(days: 1));
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
      LoadOutfitPlansForCalendar('', date, date),
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
