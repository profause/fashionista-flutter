import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileInfoTextFieldWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  const ProfileInfoTextFieldWidget({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? '',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        //const SizedBox(height: 0),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters != null ? [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]')),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          ] : null,
          obscureText: isPassword,
          enabled: enabled,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintStyle: textTheme.titleSmall,
            filled: true,
            fillColor: enabled ? Colors.transparent : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 0,
            ),
          ),
        ),
        // TextField(
        //   style: textTheme.bodyLarge,
        //   decoration: InputDecoration(
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(12),
        //       borderSide: BorderSide.none,
        //     ),
        //     labelText: label,
        //     hintText: hint,
        //     hintStyle: textTheme.titleSmall,
        //     filled: true,
        //     fillColor: enabled ? Colors.transparent : Colors.grey[50],
        //     contentPadding: const EdgeInsets.symmetric(
        //       horizontal: 4,
        //       vertical: 4,
        //     )
        //   ),
        // ),
      ],
    );
  }
}
