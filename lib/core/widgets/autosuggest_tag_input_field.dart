import 'package:fashionista/core/theme/app.theme.dart';
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
              color: context.accent,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Hashtag input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.iconSubstrate,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#',
                  style: textTheme.titleSmall?.copyWith(
                    color: context.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RawAutocomplete<String>(
                  textEditingController: _controller,
                  focusNode: _focusNode,
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }

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
                                event.logicalKey ==
                                    LogicalKeyboardKey.backspace &&
                                _controller.text.isEmpty &&
                                _tags.isNotEmpty) {
                              _removeTag(_tags.last);
                            }
                          },
                          child: TextFormField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: textTheme.bodyMedium?.copyWith(
                              color: context.onCanvasText,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.hint ?? 'Enter tags',
                              isDense: true,
                              border: InputBorder.none,
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: context.placeholderText,
                              ),
                              contentPadding: EdgeInsets.zero,
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
                        color: context.cardSurface,
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
              ),
            ],
          ),
        ),

        // Added hashtags
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((tag) => _buildTagChip(context, textTheme, tag))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, TextTheme textTheme, String tag) {
    return GestureDetector(
      onTap: () => _editTag(tag), // Tap to edit
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: context.iconSubstrate,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#',
              style: textTheme.labelMedium?.copyWith(
                color: context.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                tag,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: context.onCanvasText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: () => _removeTag(tag),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: context.secondaryLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
