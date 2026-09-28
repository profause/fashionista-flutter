import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:flutter/material.dart';

final bodyParts = [
  {"label": "Neck", "icon": Icons.add},
  {"label": "Shoulders", "icon": Icons.add},
  {"label": "Chest", "icon": Icons.add},
  {"label": "Waist", "icon": Icons.add},
  {"label": "Hips", "icon": Icons.add},
  {"label": "Thighs", "icon": Icons.add},
  {"label": "Knees", "icon": Icons.add},
  {"label": "Calves", "icon": Icons.add},
  {"label": "Ankles", "icon": Icons.add},
  {"label": "Wrists", "icon": Icons.add},
  {"label": "Forearms", "icon": Icons.add},
  {"label": "Biceps", "icon": Icons.add},
  {"label": "Triceps", "icon": Icons.add},
  {"label": "Back", "icon": Icons.add},
  {"label": "Abdomen", "icon": Icons.add},
];

class BodyPartAutocompleteFormFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String gender;
  final Set<String> measurementTemplate;

  const BodyPartAutocompleteFormFieldWidget({
    super.key,
    required this.controller,
    required this.gender,
    this.measurementTemplate = const {},
  });

  @override
  State<BodyPartAutocompleteFormFieldWidget> createState() =>
      _BodyPartAutocompleteFormFieldWidgetState();
}

class _BodyPartAutocompleteFormFieldWidgetState
    extends State<BodyPartAutocompleteFormFieldWidget> {
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

        final template = widget.measurementTemplate.isEmpty
            ? ClientMeasurement.getMeasurementTemplate(widget.gender)
            : widget.measurementTemplate;
        final matches = template
            .where((label) => label.toLowerCase().contains(query))
            .map(
              (label) => <String, dynamic>{
                'label': label,
                'icon': Icons.straighten_rounded,
              },
            )
            .toList();

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
              style: TextStyle(fontSize: 15, color: context.onCanvasText),
              decoration: InputDecoration(
                hintText: 'e.g. Chest',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.placeholderText,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
                fillColor: Colors.transparent,
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
