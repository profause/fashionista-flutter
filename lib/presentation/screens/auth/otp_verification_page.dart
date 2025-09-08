import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class OtpVerificationPage extends StatefulWidget {
  //final VoidCallback onVerified;
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
    with SingleTickerProviderStateMixin {
  late TextEditingController _otpController;
  late AnimationController _fadeController;
  late Timer _timer;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _startCountdown();
  }

  void _startCountdown() {
    //_timer.cancel();
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
    _otpController.dispose();
    _fadeController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final parallax = (widget.pageOffset - 1) * 50;
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
                  const SizedBox(height: 16),
                  Text(
                    "We’ve sent a verification code to your mobile.",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Enter One Time Password",
                      filled: true,
                      fillColor: AppTheme.lightGrey.withValues(alpha: 0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _countdown == 0 ? widget.onResend : null,
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
                        color: Colors.grey.shade400, // vertical line color
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

                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedPrimaryButton(
                      text: "Verify",
                      onPressed: () async {
                        widget.onVerified(_otpController.text.trim());
                      },
                    ),
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
