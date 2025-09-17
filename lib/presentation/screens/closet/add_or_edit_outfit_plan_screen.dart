import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
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
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    //flutterLocalNotificationsPlugin.initialize(initializationSettings);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    //final random = Random();
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Create outfit plan',
          style: textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CustomIconButtonRounded(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _saveOutfitPlan(
                    widget.outfitPlan ?? OutfitPlanModel.empty(),
                  );
                  //Navigator.of(context).pop();
                }
              },
              iconData: Icons.check,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MasonryGridView.builder(
                    shrinkWrap: true, // ✅ expands in height as items grow
                    physics:
                        const NeverScrollableScrollPhysics(), // ✅ let parent scroll
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
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: preview.url!.isEmpty
                              ? ''
                              : preview.url!.trim(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return const CustomColoredBanner(text: '');
                          },
                          errorListener: (value) {},
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CustomTextInputFieldWidget(
                      autofocus: true,
                      controller: _occasionController,
                      hint: 'Describe your style inspiration...',
                      minLines: 1,
                      maxLength: 50,
                      validator: (value) {
                        if ((value ?? "").isEmpty) {
                          return 'Describe your style inspiration...';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
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
                        Divider(thickness: 1, color: Colors.grey[300]),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Recurrence",
                            style: textTheme.titleSmall,
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
                            Text("End date", style: textTheme.titleSmall),
                            Row(
                              children: [
                                Radio<String>(
                                  value: "never",
                                  groupValue: endType,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) => setState(() {
                                    endType = val!;
                                    selectedEndDate = DateTime.now();
                                    _recurrenceEndDateController.clear();
                                  }),
                                ),
                                Text("Never", style: textTheme.titleSmall),
                              ],
                            ),
                            Row(
                              children: [
                                Radio<String>(
                                  value: "date",
                                  groupValue: endType,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) => setState(() {
                                    endType = val!;
                                    _recurrenceEndDateController.text =
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(selectedEndDate);
                                  }),
                                ),
                                Text("On date", style: textTheme.titleSmall),
                              ],
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
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedEndDate != null
                                            ? DateFormat.yMMMd().format(
                                                selectedEndDate,
                                              )
                                            : "Pick end date",
                                        style: textTheme.titleSmall,
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
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Set Reminder', style: textTheme.titleSmall),
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
                          Divider(thickness: 1, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "When would you like to be reminded?",
                              style: textTheme.titleSmall,
                            ),
                          ),
                          Row(
                            children: [
                              Radio<int>(
                                value: 10,
                                groupValue: whenToRemind,
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) => setState(() {
                                  whenToRemind = val!;
                                }),
                              ),
                              Text(
                                "10 minutes earlier",
                                style: textTheme.titleSmall,
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Radio<int>(
                                value: 60,
                                groupValue: whenToRemind,
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) => setState(() {
                                  whenToRemind = val!;
                                }),
                              ),
                              Text(
                                "An hour earlier",
                                style: textTheme.titleSmall,
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Radio<int>(
                                value: 30,
                                groupValue: whenToRemind,
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) => setState(() {
                                  whenToRemind = val!;
                                }),
                              ),
                              Text(
                                "30 minutes earlier",
                                style: textTheme.titleSmall,
                              ),
                            ],
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
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

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
          if (mounted) {
            Navigator.of(context).pop();
          }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Outfit plan saved successfully!')),
          );
          Navigator.pop(context);
          if (!isEdit) {
            Navigator.pop(context, true);
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
    // await flutterLocalNotificationsPlugin.zonedSchedule(
    //   0, // id
    //   'Outfit Reminder',
    //   message,
    //   tz.TZDateTime.from(dateTime, tz.local),
    //   details,
    //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //   matchDateTimeComponents: DateTimeComponents.dateAndTime,
    // );

    await LocalNotificationService.scheduleNotification(
      id: dateTime.millisecondsSinceEpoch ~/ 1000, // unique id
      title: "Outfit Reminder",
      body: message,
      //scheduledDate: dateTime,
      // remind 1 hour before
    );
  }
}
