import 'package:fashionista/core/routes/app_router.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class AppStarter extends StatelessWidget {
  const AppStarter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: fashionistaLightTheme,
      darkTheme: fashionistaDarkTheme,
      routerConfig: appRouter,
    );
  }
}
