import 'package:flutter/material.dart';

class OutfitTagPickerWidget extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final String? hint;
  final ValueChanged<List<String>> onChanged;

  const OutfitTagPickerWidget({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onChanged,
    this.hint,
  });

  @override
  State<OutfitTagPickerWidget> createState() => _OutfitTagPickerWidgetState();
}

class _OutfitTagPickerWidgetState extends State<OutfitTagPickerWidget> {
  late List<String> _selectedTags;
  late List<String> _allTags;
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTags);
    _allTags = List.from(widget.availableTags);
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      widget.onChanged(_selectedTags);
    });
  }

  void _addCustomTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_allTags.contains(tag)) {
      setState(() {
        _allTags.add(tag);
        _selectedTags.add(tag);
        widget.onChanged(_selectedTags);
      });
    }
    _tagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);

            return ChoiceChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (_) => _toggleTag(tag),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: textTheme.labelMedium!.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //visualDensity: VisualDensity.compact,
              //padding: EdgeInsets.zero,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: _addCustomTag,
                    icon: const Icon(Icons.add_circle),
                  ),
                  //contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  hintText: widget.hint ?? 'Add custom tag...',
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
                onSubmitted: (_) => _addCustomTag(),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}
