import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart'
    hide RecurrenceType;
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/widgets/recurrence_picker_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/date_picker_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
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
        centerTitle: true,
        title: Text(
          'Create outfit plan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.hairline),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: featuredMedia.map((preview) {
                          return Container(
                            width: 84,
                            height: 84,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: context.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.hairline),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF5A00),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${featuredMedia.length} items',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.hairline),
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

                Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DatePickerFormField(
                          label: 'Start date',
                          initialDate: widget.outfitPlan!.date > 0
                              ? DateTime.fromMillisecondsSinceEpoch(
                                  widget.outfitPlan!.date,
                                )
                              : DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(9000),
                          controller: _startDateController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please select a date'
                              : null,
                          onChanged: (date) {
                            if (date != null) {
                              final formattedDate = DateFormat(
                                'yyyy-MM-dd',
                              ).format(date);
                              _startDateController.text = formattedDate;
                            }
                          },
                        ),
                        Divider(height: 1, color: context.hairline),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Recurrence",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.onCanvasText,
                            ),
                          ),
                        ),
                        RecurrencePickerWidget(
                          initialValue: RecurrenceType.none,
                          onChanged: (type, days) {
                            //debugPrint("Recurrence: $type, Days: $days");
                            _recurrenceController.text = type.name;
                            selectedDays = days;
                          },
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "End date",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: context.onCanvasText,
                              ),
                            ),
                            RadioGroup<String>(
                              groupValue: endType,
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  endType = val;
                                  if (val == "date") {
                                    _recurrenceEndDateController.text =
                                        DateFormat('yyyy-MM-dd').format(
                                          selectedEndDate,
                                        );
                                  } else {
                                    selectedEndDate = DateTime.now();
                                    _recurrenceEndDateController.clear();
                                  }
                                });
                              },
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: "never",
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Text(
                                        "Never",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: endType == "never"
                                              ? context.onCanvasText
                                              : context.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: "date",
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Text(
                                        "On date",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: endType == "date"
                                              ? context.onCanvasText
                                              : context.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (endType == "date")
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
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: Color(0xFFFF5A00),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        // ignore: unnecessary_null_comparison
                                        selectedEndDate != null
                                            ? DateFormat.yMMMd().format(
                                                selectedEndDate,
                                              )
                                            : "Pick end date",
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
                        ),
                      ],
                    ),
                  ),
                ),
                //const SizedBox(height: 8,),
                Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
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
                            Switch(
                              value: setReminder,
                              onChanged: (val) {
                                setState(() {
                                  setReminder = val;
                                });
                              },
                            ),
                          ],
                        ),
                        if (setReminder) ...[
                          const SizedBox(height: 8),
                          Divider(height: 1, color: context.hairline),
                          const SizedBox(height: 8),
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
                          RadioGroup<int>(
                            groupValue: whenToRemind,
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                whenToRemind = val;
                              });
                            },
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Radio<int>(
                                      value: 10,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text(
                                      "10 minutes earlier",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: context.onCanvasText,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio<int>(
                                      value: 30,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text(
                                      "30 minutes earlier",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: context.onCanvasText,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio<int>(
                                      value: 60,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text(
                                      "An hour earlier",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: context.onCanvasText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
