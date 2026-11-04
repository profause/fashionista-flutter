import 'package:fashionista/core/notifications/notification_navigator.dart';
import 'package:fashionista/core/routes/app_router.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppStarter extends StatefulWidget {
  const AppStarter({super.key});

  @override
  State<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends State<AppStarter> {
  @override
  void initState() {
    super.initState();
    // A notification tap that cold-started the app is replayed once navigation
    // is safe to perform.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigator.markReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, Settings>(
      builder: (context, settings) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: fashionistaLightTheme,
        darkTheme: fashionistaDarkTheme,
        themeMode: ThemeMode.values[settings.displayMode as int],
        routerConfig: appRouter,
      ),
    );
  }
}
