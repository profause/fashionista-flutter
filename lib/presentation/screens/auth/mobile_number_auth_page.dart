import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/presentation/widgets/custom_mobilenumber_form_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Your Mobile Number",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  "We'll send you an OTP to verify your number.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),

                /// 📱 Phone number field with country selector
                CustomMobilenumberFormFieldWidget(
                  label: '',
                  hint: 'Mobile Number',
                  onChanged: (number) => _phoneNumber = number,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),

                /// 🔘 Continue button
                Align(
                  alignment: Alignment.topCenter,
                  child: Hero(
                    tag: "getStarted",
                    child: AnimatedPrimaryButton(
                      text: "Continue",
                      onPressed: () async {
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
