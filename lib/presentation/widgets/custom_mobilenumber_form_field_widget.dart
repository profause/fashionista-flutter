import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class CustomMobilenumberFormFieldWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(PhoneNumber?)? validator;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool enabled;

  const CustomMobilenumberFormFieldWidget({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Visibility(
          visible: label?.isNotEmpty == true,
          child: Text(
            label ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType!,
          obscureText: isPassword,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.outline),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0F7CF9),
                width: 1.5,
              ),
            ),
          ),
          initialCountryCode: 'GH',
          disableLengthCheck: true,
          onChanged: (phone) {
            //_phoneNumber = phone;
            onChanged?.call(phone.completeNumber);
          },
          // validator: (value) {
          //   if (value == null || value.number.isEmpty) {
          //     return 'Please enter your mobile number';
          //   }
          //   return null;
          // },
        ),
        // TextFormField(
        //   controller: controller,
        //   validator: validator,
        //   keyboardType: keyboardType,
        //   obscureText: isPassword,
        //   enabled: enabled,
        //   decoration: InputDecoration(
        //     hintText: hint,
        //     filled: true,
        //     fillColor: AppTheme.lightGrey.withValues(alpha: 0.6),
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(12),
        //       borderSide: BorderSide.none,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
