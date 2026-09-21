import 'dart:async';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpVerificationPage extends StatefulWidget {
  final ValueChanged<String> onVerified;
  final VoidCallback onChangeNumber;
  final Future<void> Function() onResend;
  final String? phoneNumber;

  const OtpVerificationPage({
    super.key,
    required this.onVerified,
    required this.onChangeNumber,
    required this.onResend,
    this.phoneNumber,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin, CodeAutoFill {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgColor =>
      _isDark ? const Color(0xFF0D0D0C) : const Color(0xFFF6FAFF);
  Color get _onSurface =>
      _isDark ? const Color(0xFFE5E2E0) : const Color(0xFF141D23);
  Color get _secondary =>
      _isDark ? const Color(0xFFA1A19A) : const Color(0xFF5D5E61);
  static const _primary = Color(0xFFFF5A00);
  Color get _borderFilled =>
      _isDark ? const Color(0xFF353533) : const Color(0xFFCBD5E1);
  Color get _borderEmpty =>
      _isDark ? const Color(0xFF2D2D2A) : const Color(0xFFE2E8F0);

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

  String get _maskedPhone {
    final raw = widget.phoneNumber ?? '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return '+••••••••••';

    if (digits.length <= 5) {
      final visiblePrefix = digits.substring(0, digits.length - 2);
      return '+$visiblePrefix${'•' * 2}';
    }

    final first3 = digits.substring(0, 3);
    final last2 = digits.substring(digits.length - 2);
    final middle = '•' * (digits.length - 5);

    return '+$first3$middle$last2';
  }

  Future<void> _submit() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 20),
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8D6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield,
                              size: 28,
                              color: _primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Enter the 6-digit code",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall!
                              .copyWith(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: _onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text.rich(
                            TextSpan(
                              text: 'Sent to your phone line ending in ',
                              style: TextStyle(fontSize: 14, color: _secondary),
                              children: [
                                TextSpan(
                                  text: _maskedPhone,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _onSurface,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// OTP Input with Auto-fill
                        /// PinInputTextField derives its box height from the
                        /// incoming height constraint, so fix it to 50.
                        /// Its inner TextField also inherits the app-wide
                        /// InputDecorationTheme (filled: true + fillColor),
                        /// so that fill must be disabled for this subtree.
                        Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme:
                                const InputDecorationThemeData(
                                  filled: false,
                                  fillColor: Colors.transparent,
                                ),
                          ),
                          child: SizedBox(
                            height: 50,
                            child: PinFieldAutoFill(
                              currentCode: _otpCode,
                              codeLength: _otpLength,
                              onCodeChanged: (value) {
                                setState(() => _otpCode = value ?? '');
                                if (value != null &&
                                    value.length == _otpLength) {
                                  widget.onVerified(value);
                                  FocusScope.of(context).unfocus();
                                }
                              },
                              onCodeSubmitted: (value) =>
                                  widget.onVerified(value),
                              decoration: BoxLooseDecoration(
                                strokeColorBuilder: PinListenColorBuilder(
                                  _borderFilled,
                                  _borderEmpty,
                                ),
                                radius: const Radius.circular(12),
                                gapSpace: 10,
                                textStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _onSurface,
                                ),
                                strokeWidth: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// Resend + Change number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_countdown > 0) ...[
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: _secondary,
                              ),
                              const SizedBox(width: 6),
                              Text.rich(
                                TextSpan(
                                  text: 'Resend code in ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _secondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${_countdown}s',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else
                              _TappableText(
                                onTap: () async {
                                  await widget.onResend();
                                  _startCountdown();
                                },
                                child: const Text(
                                  'Resend code',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            Container(
                              height: 14,
                              width: 1,
                              color: _borderFilled,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            _TappableText(
                              onTap: widget.onChangeNumber,
                              child: const Text(
                                'Change Number',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// Security trust micro-card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).cardTheme.color ??
                                Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderEmpty),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D141D23),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFE8D6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user,
                                  size: 18,
                                  color: _primary,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Protected by End-to-End Encryption",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Never share your verification pin with anyone.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: SafeArea(
                  top: false,
                  child: AnimatedPrimaryButton(
                    text: "Verify Code",
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _submit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TappableText extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TappableText({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: child,
      ),
    );
  }
}
