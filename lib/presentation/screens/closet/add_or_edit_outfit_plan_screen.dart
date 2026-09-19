import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/radio_option_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddOrEditOutfitPlanScreen extends StatefulWidget {
  final OutfitPlanModel? outfitPlan;
  const AddOrEditOutfitPlanScreen({super.key, this.outfitPlan});

  @override
  State<AddOrEditOutfitPlanScreen> createState() =>
      _AddOrEditOutfitPlanScreenState();
}

class _AddOrEditOutfitPlanScreenState extends State<AddOrEditOutfitPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startDateController;
  late TextEditingController _recurrenceEndDateController;
  late TextEditingController _recurrenceController;
  late TextEditingController _occasionController;
  late TextEditingController _recurrenceCountController;
  late List<FeaturedMediaModel> featuredMedia = [];
  late String thumbnailUrl = widget.outfitPlan?.thumbnailUrl ?? '';
  late List<int> selectedDays = [];
  late DateTime selectedEndDate;
  late DateTime selectedStartDate;
  late UserBloc userBloc;
  late bool setReminder = false;

  late bool isEdit = false;
  String? endType = "never";
  int whenToRemind = 10;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    setReminder = false;
    isEdit = widget.outfitPlan?.uid?.isNotEmpty ?? false;
    userBloc = context.read<UserBloc>();
    _startDateController = TextEditingController();
    _startDateController.text =
        widget.outfitPlan?.date != null && widget.outfitPlan!.date > 0
        ? DateTime.fromMillisecondsSinceEpoch(
            widget.outfitPlan!.date,
          ).toString()
        : DateTime.now().toString();
    selectedStartDate =
        widget.outfitPlan?.date != null && widget.outfitPlan!.date > 0
        ? DateTime.fromMillisecondsSinceEpoch(widget.outfitPlan!.date)
        : DateTime.now();

    _occasionController = TextEditingController();
    _occasionController.text = widget.outfitPlan?.occassion ?? '';

    _recurrenceEndDateController = TextEditingController();
    if (widget.outfitPlan!.recurrenceEndDate! > 0) {
      selectedEndDate = DateTime.fromMillisecondsSinceEpoch(
        widget.outfitPlan!.recurrenceEndDate!,
      );
      _recurrenceEndDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedEndDate);
      endType = "date"; // ✅ preselect "On date"
    } else {
      endType = "never";
      selectedEndDate = DateTime.now();
    }

    _recurrenceController = TextEditingController();
    _recurrenceController.text =
        widget.outfitPlan?.recurrence.isNotEmpty == true
        ? widget.outfitPlan!.recurrence
        : 'none';

    whenToRemind = widget.outfitPlan?.whenToRemind ?? 10;
    setReminder = widget.outfitPlan?.setReminder ?? false;

    _recurrenceCountController = TextEditingController();
    _recurrenceCountController.text =
        widget.outfitPlan?.recurrenceCount?.toString() ?? '';

    featuredMedia = widget.outfitPlan?.outfitItem.featuredMedia ?? [];

    // if (thumbnailUrl.isNotEmpty) {
    //   featuredMedia = [
    //     FeaturedMediaModel(
    //       aspectRatio: 1,
    //       url: thumbnailUrl,
    //       type: "image", // 👈 or whatever field your model uses
    //     ),
    //   ];
    // }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final random = Random();
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        backgroundColor: context.canvasBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 24),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Create outfit plan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: context.onCanvasText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _saveOutfitPlan(
                  widget.outfitPlan ?? OutfitPlanModel.empty(),
                );
                //Navigator.of(context).pop();
              }
            },
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.accent,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.hairline),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: featuredMedia.map((preview) {
                        return Container(
                          width: 84,
                          height: 84,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: context.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.hairline),
                            boxShadow: [_softShadow()],
                          ),
                          child: CachedNetworkImage(
                            imageUrl: (preview.url?.isEmpty ?? true)
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
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _planCaption(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                color: context.secondaryLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                    boxShadow: [_softShadow()],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _occasionController,
                          maxLength: 50,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.onCanvasText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Outfit plan name',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.placeholderText,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if ((value ?? "").isEmpty) {
                              return 'Describe your style inspiration...';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _occasionController,
                        builder: (context, value, _) {
                          return Text(
                            '${value.text.length}/50',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.placeholderText,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.hairline),
                    boxShadow: [_softShadow()],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _pickStartDate,
                        child: SizedBox(
                          height: 62,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Start date",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.secondaryLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat.yMMMd().format(
                                        selectedStartDate,
                                      ),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.3,
                                        color: context.onCanvasText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: context.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: context.hairline),
                      InkWell(
                        onTap: _openRecurrencePicker,
                        child: SizedBox(
                          height: 62,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Recurrence",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.secondaryLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _recurrenceLabel(
                                        _recurrenceController.text,
                                      ),
                                      style: TextStyle(
                                        fontSize: 15,
                                        letterSpacing: -0.3,
                                        color: context.onCanvasText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.expand_more,
                                size: 20,
                                color: context.secondaryLabel,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: context.hairline),
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "End date",
                              style: TextStyle(
                                fontSize: 12,
                                color: context.secondaryLabel,
                              ),
                            ),
                            //const SizedBox(height: 12),
                            RadioOptionRow(
                              label: "Never",
                              value: "never",
                              groupValue: endType ?? "never",
                              onChanged: _setEndType,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                            ),
                            //const SizedBox(height: 12),
                            RadioOptionRow(
                              label: "On date",
                              value: "date",
                              groupValue: endType ?? "never",
                              onChanged: _setEndType,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                            ),
                            if (endType == "date") ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedEndDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      selectedEndDate = date;
                                      _recurrenceEndDateController.text =
                                          DateFormat('yyyy-MM-dd').format(date);
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: context.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat.yMMMd().format(
                                          selectedEndDate,
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: context.onCanvasText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
                    boxShadow: [_softShadow()],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Set Reminder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.onCanvasText,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            setReminder = !setReminder;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 24,
                          padding: const EdgeInsets.all(2),
                          alignment: setReminder
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: setReminder
                                ? context.accent
                                : context.iconSubstrate,
                          ),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (setReminder) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.hairline),
                      boxShadow: [_softShadow()],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "When would you like to be reminded?",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.onCanvasText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(),
                        const SizedBox(height: 6),
                        RadioOptionRow(
                          label: "10 minutes earlier",
                          value: "10",
                          groupValue: "$whenToRemind",
                          onChanged: (v) =>
                              setState(() => whenToRemind = int.parse(v)),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                        const SizedBox(height: 6),
                        Divider(),
                        const SizedBox(height: 6),
                        RadioOptionRow(
                          label: "30 minutes earlier",
                          value: "30",
                          groupValue: "$whenToRemind",
                          onChanged: (v) =>
                              setState(() => whenToRemind = int.parse(v)),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                        const SizedBox(height: 6),
                        Divider(),
                        const SizedBox(height: 6),
                        RadioOptionRow(
                          label: "An hour earlier",
                          value: "60",
                          groupValue: "$whenToRemind",
                          onChanged: (v) =>
                              setState(() => whenToRemind = int.parse(v)),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxShadow _softShadow() {
    return BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 3),
    );
  }

  String _planCaption() {
    final occasion = _occasionController.text.trim();
    return occasion.isEmpty
        ? '${featuredMedia.length} items'
        : '$occasion • ${featuredMedia.length} items';
  }

  String _recurrenceLabel(String type) {
    switch (type) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Does not repeat';
    }
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(9000),
    );
    if (date != null) {
      setState(() {
        selectedStartDate = date;
        _startDateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  static const weekDayLabels = {
    1: "Mon",
    2: "Tue",
    3: "Wed",
    4: "Thu",
    5: "Fri",
    6: "Sat",
    7: "Sun",
  };

  void _openRecurrencePicker() {
    var tempRecurrence = _recurrenceController.text.isEmpty
        ? 'none'
        : _recurrenceController.text;
    var tempWeekDays = List<int>.from(selectedDays);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardSurface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void changeRecurrence(String value) {
              setModalState(() {
                tempRecurrence = value;
                if (value != 'weekly') tempWeekDays = [];
              });
              setState(() {
                _recurrenceController.text = value;
                if (value != 'weekly') {
                  selectedDays = [];
                } else {
                  selectedDays = List<int>.from(tempWeekDays);
                }
              });
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recurrence'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: context.mutedText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: context.canvasBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          RadioOptionRow(
                            label: "Does not repeat",
                            value: 'none',
                            groupValue: tempRecurrence,
                            onChanged: changeRecurrence,
                          ),
                          Divider(height: 1, color: context.hairline),
                          RadioOptionRow(
                            label: "Daily",
                            value: 'daily',
                            groupValue: tempRecurrence,
                            onChanged: changeRecurrence,
                          ),
                          Divider(height: 1, color: context.hairline),
                          RadioOptionRow(
                            label: "Weekly",
                            value: 'weekly',
                            groupValue: tempRecurrence,
                            onChanged: changeRecurrence,
                          ),
                          Divider(height: 1, color: context.hairline),
                          RadioOptionRow(
                            label: "Monthly",
                            value: 'monthly',
                            groupValue: tempRecurrence,
                            onChanged: changeRecurrence,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tempRecurrence == 'weekly') ...[
                    const SizedBox(height: 20),
                    Text(
                      'Weekdays'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: context.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: weekDayLabels.entries.map((entry) {
                        final isSelected = tempWeekDays.contains(entry.key);
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          onSelected: (_) {
                            setModalState(() {
                              if (tempWeekDays.contains(entry.key)) {
                                tempWeekDays.remove(entry.key);
                              } else {
                                tempWeekDays.add(entry.key);
                              }
                            });
                            setState(() {
                              selectedDays = List<int>.from(tempWeekDays);
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _setEndType(String value) {
    setState(() {
      endType = value;
      if (value == "date") {
        _recurrenceEndDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedEndDate);
      } else {
        selectedEndDate = DateTime.now();
        _recurrenceEndDateController.clear();
      }
    });
  }

  Future<void> _saveOutfitPlan(OutfitPlanModel outfitPlan) async {
    try {
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      final occassion = _occasionController.text.trim();

      final thumbnailUrl = outfitPlan.outfitItem.thumbnailUrl;
      //debugPrint("thumbnailUrl: $thumbnailUrl");
      final startDate = DateTime.parse(
        _startDateController.text,
      ).millisecondsSinceEpoch;
      final recurrenceEndDate = _recurrenceEndDateController.text.isNotEmpty
          ? DateTime.parse(
              _recurrenceEndDateController.text,
            ).millisecondsSinceEpoch
          : 0;

      final outfitPlanId = isEdit ? outfitPlan.uid : Uuid().v4();
      final createdAt = isEdit
          ? outfitPlan.createdAt
          : DateTime.now().millisecondsSinceEpoch;

      int recurrenceCount = 0;
      if (recurrenceEndDate > 0) {
        //get the number of dates between start date and end date inclusive
        recurrenceCount =
            DateTime.fromMillisecondsSinceEpoch(recurrenceEndDate)
                .difference(DateTime.fromMillisecondsSinceEpoch(startDate))
                .inDays +
            1;
      }

      // Show progress dialog
      showLoadingDialog(context);

      outfitPlan = outfitPlan.copyWith(
        uid: outfitPlanId,
        occassion: occassion,
        createdAt: createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdBy: createdBy,
        date: startDate,
        recurrenceEndDate: recurrenceEndDate,
        daysOfWeek: selectedDays,
        recurrence: _recurrenceController.text,
        recurrenceCount: recurrenceCount,
        note: occassion,
        thumbnailUrl: thumbnailUrl,
        whenToRemind: whenToRemind,
        setReminder: setReminder,
      );
      final result = isEdit
          ? await sl<FirebaseClosetService>().updateOutfitPlan(outfitPlan)
          : await sl<FirebaseClosetService>().addOutfitPlan(outfitPlan);

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
          dismissLoadingDialog(context);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) async {
          // _buttonLoadingStateCubit.setLoading(false);
          if (!mounted) return;
          context.read<ClosetOutfitBloc>().add(
            const LoadOutfitsCacheFirstThenNetwork(''),
          );
          if (setReminder) {
            //schedule notification
            DateTime remiderDate = DateTime.fromMillisecondsSinceEpoch(
              outfitPlan.date,
            ).subtract(Duration(minutes: whenToRemind));
            await scheduleOutfitReminder(
              remiderDate,
              "Your outfit for ${outfitPlan.occassion} is scheduled!",
            );
          }
          final ctx = context;
          if (!ctx.mounted) return;
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('✅ Outfit plan saved successfully!')),
          );
          dismissLoadingDialog(ctx);
          if (!isEdit) {
            Navigator.pop(ctx, true);
          }
        },
      );
    } on firebase_auth.FirebaseException catch (e) {
      //_buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _occasionController.dispose();
    _recurrenceEndDateController.dispose();
    _recurrenceController.dispose();
    _recurrenceCountController.dispose();
    super.dispose();
  }

  Future<void> scheduleOutfitReminder(DateTime dateTime, String message) async {
    await LocalNotificationService.scheduleNotification(
      id: dateTime.millisecondsSinceEpoch ~/ 1000, // unique id
      title: "Outfit Reminder",
      body: message,
      scheduledDate: dateTime,
      // remind 1 hour before
    );
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
