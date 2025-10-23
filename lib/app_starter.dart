import 'package:fashionista/core/routes/app_router.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppStarter extends StatelessWidget {
  const AppStarter({super.key});

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
