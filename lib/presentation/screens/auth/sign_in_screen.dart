import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/bloc/previous_screen_state_cubit.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/domain/usecases/auth/signin_usecase.dart';
import 'package:fashionista/domain/usecases/auth/verify_otp_usecase.dart';
import 'package:fashionista/presentation/screens/auth/mobile_number_auth_page.dart';
import 'package:fashionista/presentation/screens/auth/otp_verification_page.dart';
import 'package:fashionista/presentation/screens/main/main_screen.dart';
import 'package:fashionista/presentation/screens/profile/create_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'dart:io' show Platform;

import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';

bool isIOS = Platform.isIOS;

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  RecaptchaClient? _recaptchaClient;

  final PageController _pageController = PageController();
  String otpString = "";
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;
  late PreviousScreenStateCubit _previousScreenStateCubit;
  late AuthProviderCubit _authProviderCubit;
  late UserBloc _userBloc;
  final ValueNotifier<String> _verificationId = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _initRecaptcha(); // 👈 kick off async call
    _pageController.addListener(() {});
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
    final colorScheme = Theme.of(context).colorScheme;

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
    return ValueListenableBuilder<String>(
      valueListenable: _verificationId,
      builder: (context, verificationId, _) {
        otpString = verificationId;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            foregroundColor: colorScheme.primary,
            backgroundColor: colorScheme.onPrimary,
            title: Text(
              'Sign In',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
          ),
          backgroundColor: colorScheme.surface,
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

      result.fold(
        (ifLeft) {
          _buttonLoadingStateCubit.setLoading(false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          _buttonLoadingStateCubit.setLoading(false);
          otpString = ifRight.toString();
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
        verificationId: otpString,
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
          _buttonLoadingStateCubit.setLoading(false);
          _authProviderCubit.setAuthState(
            ifRight?.displayName ?? 'Guest user',
            ifRight?.phoneNumber ?? '',
            ifRight?.uid ?? '',
            true,
          );

          var loggedInUser = _userBloc.state.copyWith(
            fullName: ifRight?.displayName ?? 'Guest user',
            userName: ifRight?.displayName ?? 'Guest user',
            mobileNumber: ifRight?.phoneNumber ?? '233543756168',
            uid: ifRight?.uid ?? '',
            joinedDate: ifRight.metadata.creationTime,
          );
          _userBloc.add(UpdateUser(loggedInUser));
          final user = _userBloc.state;
          final isFullNameEmpty = user.fullName.isEmpty;
          final isUserNameEmpty = user.userName == 'Guest user';
          final isAccountTypeEmpty = user.accountType.isEmpty;
          final isGenderEmpty = user.gender.isEmpty;

          if (isFullNameEmpty ||
              isUserNameEmpty ||
              isAccountTypeEmpty ||
              isGenderEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateProfileScreen(),
              ),
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const MainScreen(),
              ),
              (route) => false,
            );
          }
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

  Future<RecaptchaClient> initialiseRecapture() async {
    final siteKey = Platform.isAndroid
        ? "6LcvZLMrAAAAAC9BgMgVkpuuUZpxrBRW6rdvENEt"
        : "6LerVrMrAAAAALXzsXfdT-v8p0iKKxIrK2FrByQU";
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
