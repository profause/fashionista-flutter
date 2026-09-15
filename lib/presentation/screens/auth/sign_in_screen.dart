import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/onboarding/onboarding_cubit.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/bloc/previous_screen_state_cubit.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/domain/usecases/auth/signin_usecase.dart';
import 'package:fashionista/domain/usecases/auth/verify_otp_usecase.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:fashionista/presentation/screens/auth/mobile_number_auth_page.dart';
import 'package:fashionista/presentation/screens/auth/otp_verification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'dart:io' show Platform;

import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  RecaptchaClient? _recaptchaClient;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;
  late PreviousScreenStateCubit _previousScreenStateCubit;
  late AuthProviderCubit _authProviderCubit;
  late UserBloc _userBloc;
  final ValueNotifier<String> _verificationId = ValueNotifier('');
  late OnboardingCubit _onboardingCubit;

  @override
  void initState() {
    _onboardingCubit = context.read<OnboardingCubit>();
    _onboardingCubit.hasSeenOnboarding(true); //here
    super.initState();
    _initRecaptcha(); // 👈 kick off async call
    _pageController.addListener(() {
      if (!mounted) return;
      final index = _pageController.page?.round() ?? 0;
      if (index != _currentPage) {
        setState(() => _currentPage = index);
      }
    });
    if (mounted) {
      _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
      _previousScreenStateCubit = context.read<PreviousScreenStateCubit>();
      _previousScreenStateCubit.setPreviousScreen('SignInScreen');
      _authProviderCubit = context.read<AuthProviderCubit>();
      _userBloc = context.read<UserBloc>();
    }
  }

  void nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_recaptchaClient == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final pages = [
      MobileNumberAuthPage(
        controller: _pageController,
        onNumberSubmitted: (number) async {
          await sendOtp(number);
        },
      ),
      OtpVerificationPage(
        phoneNumber: _authProviderCubit.authState.mobileNumber,
        onVerified: (otp) async {
          await verifyOneTimePassword(otp);
        },
        onChangeNumber: () {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        onResend: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
      ),
    ];
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder<String>(
        valueListenable: _verificationId,
        builder: (context, verificationId, _) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              title: Text(
                _currentPage == 0 ? 'Sign In' : 'Otp Verification',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: SizedBox(
                  height: 1,
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              //tag: "getStartedButton",
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return pages[index];
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> sendOtp(String number) async {
    try {
      _buttonLoadingStateCubit.setLoading(true);
      var result = await sl<SignInUsecase>().call(number);
      _authProviderCubit.setAuthState('', number, '', false);
      result.fold(
        (ifLeft) {
          _buttonLoadingStateCubit.setLoading(false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          _buttonLoadingStateCubit.setLoading(false);
          _verificationId.value = ifRight.toString();
          nextPage();
        },
      );
    } on FirebaseAuthException catch (e) {
      _buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  Future<void> verifyOneTimePassword(String otp) async {
    try {
      _buttonLoadingStateCubit.setLoading(true);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId.value,
        smsCode: otp,
      );

      var result = await sl<VerifyOtpUsecase>().call(credential);

      result.fold(
        (ifLeft) {
          _buttonLoadingStateCubit.setLoading(false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          if (!mounted) return;
          _authProviderCubit.setAuthState(
            ifRight?.displayName ?? '',
            ifRight?.phoneNumber ?? _authProviderCubit.authState.mobileNumber,
            ifRight?.uid ?? '',
            true,
          );

          var loggedInUser = _userBloc.state.copyWith(
            fullName: ifRight?.displayName ?? '',
            userName: ifRight?.displayName ?? '',
            mobileNumber:
                ifRight?.phoneNumber ??
                _authProviderCubit.authState.mobileNumber,
            uid: ifRight?.uid ?? '',
            joinedDate: ifRight.metadata.creationTime,
          );
          _userBloc.add(UpdateUser(loggedInUser));
          _userBloc.stream.first.then((updatedUser) async {
            await _getUserDetails();
            // use updatedUser
          });
        },
      );
    } on FirebaseAuthException catch (e) {
      _buttonLoadingStateCubit.setLoading(false);
      debugPrint(e.toString());
      if (!mounted) return;
      _buttonLoadingStateCubit.setLoading(false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _getUserDetails() async {
    try {
      final userBloc = context.read<UserBloc>();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final result = await sl<FetchUserProfileUsecase>().call(uid);
      result.fold(
        (ifLeft) {
          _buttonLoadingStateCubit.setLoading(false);

          if (mounted) {
            // Dismiss the dialog manually
            debugPrint(ifLeft);
            //dismissLoadingDialog(context);
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          _buttonLoadingStateCubit.setLoading(false);
          if (ifRight.uid!.isNotEmpty) {
            //userBloc.clear();
            userBloc.add(UpdateUser(ifRight));

            final isFullNameEmpty = ifRight.fullName.isEmpty;
            final isUserNameEmpty = ifRight.userName.isEmpty;
            final isAccountTypeEmpty = ifRight.accountType.isEmpty;
            final isGenderEmpty = ifRight.gender.isEmpty;

            if (isFullNameEmpty ||
                isUserNameEmpty ||
                isAccountTypeEmpty ||
                isGenderEmpty) {
              context.go('/create-profile');
            } else {
              //context.go('/create-profile');
              context.go('/home');
            }
          } else {
            context.go('/create-profile');
          }
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      _buttonLoadingStateCubit.setLoading(false);
    }
  }

  Future<RecaptchaClient> initialiseRecapture() async {
    final siteKey = Platform.isAndroid
        ? appConfig.get('recaptcha_site_key_android')
        : appConfig.get('recaptcha_site_key_ios');
    RecaptchaClient client = await Recaptcha.fetchClient(siteKey);

    return client;
  }

  Future<void> _initRecaptcha() async {
    try {
      final client = await initialiseRecapture();
      if (mounted) {
        setState(() {
          _recaptchaClient = client;
        });
      }
    } catch (e) {
      debugPrint("Error initializing reCAPTCHA: $e");
      // You can show a snackbar or handle error UI here if needed
    }
  }
}
