import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/presentation/widgets/custom_mobilenumber_form_field_widget.dart';
import 'package:flutter/material.dart';

class MobileNumberAuthPage extends StatefulWidget {
  final PageController controller;
  final ValueChanged<String> onNumberSubmitted;

  const MobileNumberAuthPage({
    super.key,
    required this.controller,
    required this.onNumberSubmitted,
  });

  @override
  State<MobileNumberAuthPage> createState() => _MobileNumberAuthPageState();
}

class _MobileNumberAuthPageState extends State<MobileNumberAuthPage> {
  final _formKey = GlobalKey<FormState>();
  String? _phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDBCE).withValues(
                                alpha: 0.6,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5A00).withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.phone_android_outlined,
                              size: 28,
                              color: Color(0xFFFF5A00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Enter your mobile number',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall!
                              .copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "We'll send a 6-digit OTP code to verify your phone.",
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomMobilenumberFormFieldWidget(
                          label: '',
                          hint: '00 000 0000',
                          onChanged: (number) => _phoneNumber = number,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: Hero(
                    tag: "getStarted",
                    child: AnimatedPrimaryButton(
                      text: "Continue",
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        if (!_formKey.currentState!.validate()) return;

                        if (_phoneNumber == null || _phoneNumber!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Enter mobile number to proceed"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        final number = _phoneNumber!;
                        widget.onNumberSubmitted(number);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}