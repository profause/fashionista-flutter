import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AutosuggestTagInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final Function(List<String>)? valueOut;
  final List<String>? valueIn;
  final List<String>? options;

  const AutosuggestTagInputField({
    super.key,
    this.label,
    this.hint,
    this.valueOut,
    this.valueIn,
    this.options,
  });

  @override
  State<AutosuggestTagInputField> createState() =>
      _AutosuggestTagInputFieldState();
}

class _AutosuggestTagInputFieldState extends State<AutosuggestTagInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.valueIn != null) {
      _tags.addAll(widget.valueIn!);
      widget.valueOut?.call(_tags);
    }
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _controller.clear();
      });
      widget.valueOut?.call(_tags);
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.valueOut?.call(_tags);
  }

  void _editTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _controller.text = tag;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: tag.length),
      );
      _focusNode.requestFocus();
    });
    widget.valueOut?.call(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Tag chips
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
                        fontSize: 13,
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
        const SizedBox(height: 8),

        // Input field with autocomplete
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return const Iterable<String>.empty();

            final query = value.text.toLowerCase();
            final matches =
                widget.options
                    ?.where(
                      (option) =>
                          option.toLowerCase().contains(query) &&
                          !_tags.contains(option),
                    )
                    .toList() ??
                [];

            // Allow free text entry if no match
            if (matches.isEmpty) return [value.text];
            return matches;
          },
          displayStringForOption: (option) => option,
          fieldViewBuilder:
              (
                context,
                textEditingController,
                fieldFocusNode,
                onFieldSubmitted,
              ) {
                return KeyboardListener(
                  focusNode: _keyboardFocusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _controller.text.isEmpty &&
                        _tags.isNotEmpty) {
                      _removeTag(_tags.last);
                    }
                  },
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: widget.hint ?? 'Enter tags',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: textTheme.titleSmall!.copyWith(
                        fontSize: 13
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                    ),
                    onFieldSubmitted: (value) {
                      _addTag(value);
                    },
                    onChanged: (value) {
                      if (value.endsWith(' ') || value.endsWith(',')) {
                        _addTag(value.substring(0, value.length - 1));
                      }
                    },
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.onPrimary,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                          _addTag(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
