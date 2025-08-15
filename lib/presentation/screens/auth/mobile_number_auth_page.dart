import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/primary_text_field.dart';
import 'package:flutter/material.dart';

class MobileNumberAuthPage extends StatelessWidget {
  //final double pageOffset;
  // final VoidCallback onNext;

  final PageController controller;
  final ValueChanged<String> onNumberSubmitted;

  const MobileNumberAuthPage({
    super.key,
    required this.controller,
    required this.onNumberSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // final parallax = (widget.pageOffset - 0) * 50;
    final colorScheme = Theme.of(context).colorScheme;
    final mobileNumberTextFieldController = TextEditingController();
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          // ensures it's still scrollable on small screens
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // centers vertically
            crossAxisAlignment:
                CrossAxisAlignment.start, // keeps left text alignment
            children: [
              Text(
                "Enter Your Mobile Number",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              Text(
                "We'll send you an OTP to verify your number.",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 32),
              PrimaryTextField(
                label: '',
                hint: 'Mobile Number',
                controller: mobileNumberTextFieldController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 40),
              Align(
                alignment: Alignment.bottomCenter,
                child: Hero(
                  tag: "getStarted",
                  child: AnimatedPrimaryButton(
                    text: "Continue",
                    onPressed: () async {
                      final number = mobileNumberTextFieldController.text
                          .trim();
                      final isValid = RegExp(
                        r'^(\+?\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$',
                      ).hasMatch(number);

                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Enter mobile number to proceed"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return; // Stop here if invalid
                      }
                      onNumberSubmitted(number);
                    },
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
