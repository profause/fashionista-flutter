import 'dart:async';
import 'package:fashionista/core/assets/app_vectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/theme/app.theme.dart';

class OtpVerificationPage extends StatefulWidget {
  final ValueChanged<String> onVerified;
  final VoidCallback onChangeNumber;
  final Future<void> Function() onResend;

  const OtpVerificationPage({
    super.key,
    required this.onVerified,
    required this.onChangeNumber,
    required this.onResend,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin, CodeAutoFill {
  final int _otpLength = 6;
  late AnimationController _fadeController;
  late Timer _timer;
  int _countdown = 60;
  String _otpCode = "";

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    listenForCode(); // Start listening for OTP SMS
    _startCountdown();
  }

  @override
  void codeUpdated() {
    setState(() => _otpCode = code ?? '');
    if (_otpCode.length == _otpLength) {
      widget.onVerified(_otpCode);
    }
  }

  void _startCountdown() {
    _countdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    cancel(); // stop listening for SMS
    _fadeController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      AppVectors.enterPasswordImage,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Enter the 6-digit code sent to your phone",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  /// OTP Input with Auto-fill
                  PinFieldAutoFill(
                    currentCode: _otpCode,
                    codeLength: _otpLength,
                    onCodeChanged: (value) {
                      setState(() => _otpCode = value ?? '');
                      if (value != null && value.length == _otpLength) {
                        widget.onVerified(value);
                        /// 🔽 Close keyboard
                        FocusScope.of(context).unfocus();
                      }
                    },
                    onCodeSubmitted: (value) => widget.onVerified(value),
                    decoration: BoxLooseDecoration(
                      strokeColorBuilder: FixedColorBuilder(
                        AppTheme.lightGrey.withValues(alpha: 0.9),
                      ),
                      bgColorBuilder: FixedColorBuilder(
                        AppTheme.lightGrey.withValues(alpha: 0.9),
                      ),
                      radius: const Radius.circular(12), // ✅ Rounded corners
                      gapSpace: 12, // spacing between boxes
                      textStyle: Theme.of(context).textTheme.titleLarge,
                      strokeWidth: 2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Resend + Change number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _countdown == 0
                            ? () async {
                                await widget.onResend();
                                _startCountdown();
                              }
                            : null,
                        child: Text(
                          _countdown == 0
                              ? "Resend OTP"
                              : "Resend in $_countdown s",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade400,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onChangeNumber,
                          child: Text(
                            "Change Mobile Number",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  AnimatedPrimaryButton(
                    text: "Verify",
                    onPressed: () async {
                      /// 🔽 Close keyboard
                      FocusScope.of(context).unfocus();
                      if (_otpCode.length < _otpLength) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter all 6 digits."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      widget.onVerified(_otpCode);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
