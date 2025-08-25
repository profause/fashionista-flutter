import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/onboarding/onboarding_cubit.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/main/main_screen.dart';
import 'package:fashionista/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:fashionista/presentation/screens/profile/create_profile_screen.dart';
import 'package:fashionista/presentation/screens/splash/widgets/animated_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  //late Animation<double> _fadeAnimation;
  //late Animation<Offset> _slideAnimation;
  //late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(microseconds: 1500),
    );

    // _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    //   CurvedAnimation(
    //     parent: _controller,
    //     curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    //   ),
    // );

    // _slideAnimation =
    //     Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
    //       CurvedAnimation(
    //         parent: _controller,
    //         curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    //       ),
    //     );

    // _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
    //   CurvedAnimation(
    //     parent: _controller,
    //     curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    //   ),
    // );

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _onboardingCubit = context.read<OnboardingCubit>();
        _authProviderCubit = context.read<AuthProviderCubit>();
        _userBloc = context.read<UserBloc>();
        Widget nextScreen;

        if (!_onboardingCubit.hasCompletedOnboarding) {
          nextScreen = const OnboardingScreen();
        } else if (!_authProviderCubit.authState.isAuthenticated) {
          nextScreen = const SignInScreen();
        } else if (_userBloc.state.accountType.isEmpty ||
            _userBloc.state.gender.isEmpty) {
          nextScreen = const CreateProfileScreen();
        } else {
          nextScreen = const MainScreen();
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
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
      backgroundColor: AppTheme.charcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FadeTransition(
            //   opacity: _fadeAnimation,
            //   child: SlideTransition(
            //     position: _slideAnimation,
            //     child: ScaleTransition(
            //       scale: _scaleAnimation,
            //       child: Container(
            //         width: 120,
            //         height: 120,
            //         padding: const EdgeInsets.all(12),
            //         decoration: BoxDecoration(
            //           color: AppTheme.white.withValues(alpha: 0.1),
            //           borderRadius: BorderRadius.circular(30),
            //         ),
            //         child: Container(
            //           decoration: BoxDecoration(
            //             color: AppTheme.white,
            //             borderRadius: BorderRadius.circular(20),
            //           ),
            //           child: RoundedImage(
            //             imageUrl: AppImages.appLogo,
            //             isAsset: true,
            //             borderRadius: 30,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
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
