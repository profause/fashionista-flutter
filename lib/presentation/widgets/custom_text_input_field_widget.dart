import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextInputFieldWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final int? minLines;
  final int? maxLength; // optional to cap text length

  const CustomTextInputFieldWidget({
    super.key,
    this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLength, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label ?? '',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200, // prevent growing infinitely
          ),
          child: TextFormField(
            onChanged: onChanged,
            autofocus: autofocus,
            controller: controller,
            validator: validator,
            keyboardType: isPassword
                ? TextInputType.text
                : (keyboardType ?? TextInputType.multiline),
            inputFormatters: inputFormatters,
            obscureText: isPassword,
            enabled: enabled,
            minLines: isPassword ? 1 : minLines, // starting height
            maxLines: isPassword ? 1 : null, // auto expand when typing
            maxLength: maxLength,
            style: textTheme.labelLarge,
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
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
