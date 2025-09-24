import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TagInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(List<String>)? valueOut;
  final List<String>? valueIn;

  const TagInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.valueOut,
    this.valueIn,
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFieldFocusNode =
      FocusNode(); // separate for TextFormField
  final FocusNode _keyboardFocusNode = FocusNode(); // for RawKeyboardListener
  final List<String> _tags = [];

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _controller.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.valueOut?.call(_tags);
    });
  }

  void _editTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.valueOut?.call(_tags);
      _controller.text = tag;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: tag.length),
      );
      _textFieldFocusNode.requestFocus();
    });
  }

  @override
  void initState() {
    if (widget.valueIn != null) {
      setState(() {
        _tags.addAll(widget.valueIn!);
        widget.valueOut?.call(_tags);
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12.0,
          runSpacing: 6.0,
          children: _tags.map((tag) {
            return GestureDetector(
              onTap: () => _editTag(tag), // Tap to edit
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: .5),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label ?? '',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
        // FIX: use different focus node here
        KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                _controller.text.isEmpty &&
                _tags.isNotEmpty) {
              _removeTag(_tags.last); // delete last tag
            }
          },
          child: TextFormField(
            controller: _controller,
            focusNode: _textFieldFocusNode,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Enter tags',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintStyle: textTheme.titleSmall,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 0,
              ),
            ),
            onFieldSubmitted: (value) {
              _addTag(value);
              widget.valueOut?.call(_tags);
            }, // Enter
            onChanged: (value) {
              if (value.endsWith(" ") || value.endsWith(",")) {
                _addTag(value.substring(0, value.length - 1));
              }
              widget.valueOut?.call(_tags);
            },
          ),
        ),
      ],
    );
  }
}
