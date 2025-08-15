import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/bloc/previous_screen_state_cubit.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/domain/usecases/auth/signin_usecase.dart';
import 'package:fashionista/presentation/screens/auth/mobile_number_auth_page.dart';
import 'package:fashionista/presentation/screens/auth/otp_verification_page.dart';
import 'package:fashionista/presentation/screens/main/main_screen.dart';
import 'package:fashionista/presentation/screens/profile/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final PageController _pageController = PageController();
  String otpString = "";
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;
  late PreviousScreenStateCubit _previousScreenStateCubit;
  late AuthProviderCubit _authProviderCubit;
  late UserBloc _userBloc;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {});
    if (mounted) {
      _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
      _previousScreenStateCubit = context.read<PreviousScreenStateCubit>();
      _previousScreenStateCubit.setPreviousScreen('SignInScreen');
      //this temporary code should be removed
      _authProviderCubit = context.read<AuthProviderCubit>();
      _authProviderCubit.setAuthState('Guest user', '', '233543756168', true);
      _userBloc = context.read<UserBloc>();

      var loggedInUser = _userBloc.state.copyWith(
        userName: 'Guest user',
        mobileNumber: '233543756168',
      );
      _userBloc.add(UpdateUser(loggedInUser));
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
    final pages = [
      MobileNumberAuthPage(
        controller: _pageController,
        onNumberSubmitted: (number) async {
          debugPrint("Mobile number submitted: $number");
          await sendOtp(number);
        },
      ),
      OtpVerificationPage(
        onVerified: (otp) async {
          debugPrint("otp submitted: $otp");
          await verifyOneTimePassword(otp);
        },
        onChangeNumber: () {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        onResend: () async {
          debugPrint("OTP Resent");
          await Future.delayed(const Duration(seconds: 1));
        },
      ),
    ];
    return Scaffold(
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
      // body: Center(
      //   child: Hero(
      //     tag: "getStartedButton",
      //     child: AnimatedPrimaryButton(
      //       text: "Get Started",
      //       onPressed: () {
      //         // Navigate to login/signup
      //       },
      //     ),
      //   ),
      // ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  Future<void> sendOtp(String number) async {
    try {
      debugPrint("Mobile number submitted again: $number");
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
          nextPage();
        },
      );

      // await FirebaseAuth.instance.verifyPhoneNumber(
      //   phoneNumber: number,
      //   verificationCompleted: (PhoneAuthCredential credential) {
      //     _buttonLoadingStateCubit.setLoading(false);
      //   },
      //   verificationFailed: (FirebaseAuthException e) {
      //     debugPrint(e.toString());
      //     _buttonLoadingStateCubit.setLoading(false);
      //   },
      //   codeSent: (String verificationId, int? resendToken) {
      //     debugPrint("Code Sent");
      //     otpString = verificationId;
      //     _buttonLoadingStateCubit.setLoading(false);
      //     nextPage();
      //   },
      //   codeAutoRetrievalTimeout: (String verificationId) {
      //     debugPrint("Timeout");
      //     _buttonLoadingStateCubit.setLoading(false);
      //   },
      // );
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
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
      await FirebaseAuth.instance.signInWithCredential(credential).then((
        onValue,
      ) {
        if (!mounted) return;
        _buttonLoadingStateCubit.setLoading(false);
        debugPrint("Verification Completed");
        debugPrint(onValue.user.toString());
        //final uid = onValue.user?.uid;
        _authProviderCubit.setAuthState(
          onValue.user?.displayName ?? 'Guest user',
          onValue.user?.phoneNumber ?? '',
          onValue.user?.uid ?? '',
          true,
        );

        var loggedInUser = _userBloc.state.copyWith(
          userName: onValue.user?.displayName ?? 'Guest user',
          mobileNumber: onValue.user?.phoneNumber ?? '233543756168',
          uid: onValue.user?.uid ?? '',
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
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      _buttonLoadingStateCubit.setLoading(false);
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
