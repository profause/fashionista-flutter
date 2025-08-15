import 'package:fashionista/core/onboarding/onboarding_cubit.dart';
import 'package:fashionista/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppStarter extends StatelessWidget {
  const AppStarter({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => OnboardingCubit())],
      child: const SplashScreen(),
    );
  }
}
