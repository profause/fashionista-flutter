import 'package:flutter/material.dart';

class CustomAutocompleteFormFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> autoCompleteItems;
  final String hintText;

  const CustomAutocompleteFormFieldWidget({
    super.key,
    required this.controller, required this.autoCompleteItems,
    required this.hintText,
  });

  @override
  State<CustomAutocompleteFormFieldWidget> createState() =>
      _CustomAutocompleteFormFieldWidgetState();
}

class _CustomAutocompleteFormFieldWidgetState
    extends State<CustomAutocompleteFormFieldWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.toLowerCase();

        if (query.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }

        // Filter categories
        final matches = widget.autoCompleteItems.where((cat) {
          final label = (cat["label"] as String?) ?? '';
          return label.toLowerCase().contains(query);
        });

        // If no match, allow free-text
        if (matches.isEmpty) {
          return [
            {"label": textEditingValue.text, "icon": Icons.add},
          ];
        }

        return matches;
      },
      displayStringForOption: (option) => option["label"] as String,
      fieldViewBuilder:
          (context, fieldController, fieldFocusNode, onFieldSubmitted) {
            return TextFormField(
              controller: widget.controller, // external controller
              focusNode: _focusNode,
              onFieldSubmitted: (_) => onFieldSubmitted(),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                hintText: widget.hintText,
                suffixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 25,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    leading: Icon(
                      option["icon"] as IconData,
                      color: colorScheme.primary,
                    ),
                    title: Text(option["label"], style: textTheme.bodyMedium),
                    onTap: () {
                      widget.controller.text = option["label"] as String;
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
