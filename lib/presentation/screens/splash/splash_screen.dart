import 'package:fashionista/core/assets/app_images.dart';
import 'package:fashionista/core/assets/rounded_image.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/onboarding/onboarding_cubit.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/splash/widgets/animated_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late OnboardingCubit _onboardingCubit;
  late AuthProviderCubit _authProviderCubit;
  late UserBloc _userBloc;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(microseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _onboardingCubit = context.read<OnboardingCubit>();
        _authProviderCubit = context.read<AuthProviderCubit>();
        _userBloc = context.read<UserBloc>();
        String nextScreen;

        if (!_onboardingCubit.hasCompletedOnboarding) {
        //if(true){
          nextScreen = '/onboarding';
        } else if (!_authProviderCubit.authState.isAuthenticated) {
          nextScreen = '/sign-in';
        } else if (_userBloc.state.accountType.isEmpty ||
            _userBloc.state.gender.isEmpty) {
          nextScreen = '/create-profile';
        } else {
          nextScreen = '/home';
        }

        context.go(nextScreen);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appIconColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.appIconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: RoundedImage(
                        imageUrl: AppImages.appLogo,
                        isAsset: true,
                        borderRadius: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedTitle(),
            // FadeTransition(
            //   opacity: _fadeAnimation,
            //   child: SlideTransition(
            //     position: _slideAnimation,
            //     child: Hero(
            //       tag: "getStartedButton",
            //       child: Text("Fashionista", style: AppTheme.appTitleStyle),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
