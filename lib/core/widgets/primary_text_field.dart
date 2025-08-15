import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class PrimaryTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;

  const PrimaryTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
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
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: isPassword,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.lightGrey.withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
