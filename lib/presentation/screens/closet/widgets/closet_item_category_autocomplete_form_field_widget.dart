import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/presentation/screens/closet/widgets/closet_item_categories_widget.dart';
import 'package:flutter/material.dart';

class ClosetItemCategoryAutocompleteFormFieldWidget extends StatefulWidget {
  final TextEditingController controller;

  const ClosetItemCategoryAutocompleteFormFieldWidget({
    super.key,
    required this.controller,
  });

  @override
  State<ClosetItemCategoryAutocompleteFormFieldWidget> createState() =>
      _ClosetItemCategoryAutocompleteFormFieldWidgetState();
}

class _ClosetItemCategoryAutocompleteFormFieldWidgetState
    extends State<ClosetItemCategoryAutocompleteFormFieldWidget> {
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
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.toLowerCase();

        if (query.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }

        // Filter categories
        final matches = categories.where((cat) {
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
              style: TextStyle(
                fontSize: 15,
                color: context.onCanvasText,
              ),
              decoration: InputDecoration(
                hintText: "Pick or type a category ✨",
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: context.placeholderText,
                ),
                suffixIcon: Icon(
                  Icons.expand_more_rounded,
                  color: context.secondaryLabel,
                ),
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.hairline),
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
                      color: context.accent,
                    ),
                    title: Text(
                      option["label"],
                      style: TextStyle(
                        fontSize: 15,
                        color: context.onCanvasText,
                      ),
                    ),
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
