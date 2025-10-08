import 'dart:async';
import 'dart:io';

import 'package:fashionista/app_starter.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/onboarding/onboarding_cubit.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/theme/theme_cubit.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/bloc/getstarted_stats_cubit.dart';
import 'package:fashionista/core/widgets/bloc/previous_screen_state_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_plan_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/design_collection_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_feedback_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_review_bloc.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc.dart';
import 'package:fashionista/presentation/screens/clients/clients_screen.dart';
import 'package:fashionista/presentation/screens/closet/closet_items_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'firebase_options.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );

  await initialiseDependencies();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Ensure Hive is ready before app starts
  await HiveService().init();

  await _configureLocalTimeZone();
  await LocalNotificationService.init();

  runApp(const MyApp());
}

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  if (Platform.isWindows) {
    return;
  }
  final TimezoneInfo timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => OnboardingCubit()),
        BlocProvider(create: (_) => AuthProviderCubit()),
        BlocProvider(create: (_) => ButtonLoadingStateCubit()),
        BlocProvider(create: (_) => PreviousScreenStateCubit()),
        BlocProvider(create: (_) => UserBloc()),
        BlocProvider(create: (_) => SettingsBloc()),
        BlocProvider(create: (_) => ClientBloc()),
        BlocProvider(create: (_) => DesignerBloc()),
        BlocProvider(create: (_) => DesignCollectionBloc()),
        BlocProvider(create: (_) => TrendBloc()),
        BlocProvider(create: (_) => TrendCommentBloc()),
        BlocProvider(create: (_) => ClosetOutfitBloc()),
        BlocProvider(create: (_) => ClosetItemBloc()),
        BlocProvider(create: (_) => ClosetOutfitPlannerBloc()),
        BlocProvider(create: (_) => WorkOrderBloc()),
        BlocProvider(create: (_) => WorkOrderStatusProgressBloc()),
        BlocProvider(create: (_) => DesignerFeedbackBloc()),
        BlocProvider(create: (_) => GetstartedStatsCubit()),
        BlocProvider(create: (_) => DesignerReviewBloc()),
      ],

      child: BlocBuilder<SettingsBloc, Settings>(
        builder: (context, settings) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: fashionistaLightTheme,
          darkTheme: fashionistaDarkTheme,
          themeMode: ThemeMode.values[settings.displayMode as int],
          navigatorObservers: [routeObserver, closetItemPageRouteObserver],
          home: const AppStarter(),
          // routes: {
          //   '/clients': (_) => const ClientsScreen(),
          //   '/add-client': (_) => const AddClientScreen(),
          // },
        ),
      ),
    );
  }
}
