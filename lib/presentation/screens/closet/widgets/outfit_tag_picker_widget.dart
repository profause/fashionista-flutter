import 'package:fashionista/core/theme/app.theme.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);

            return GestureDetector(
              onTap: () => _toggleTag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? context.accent : context.cardSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: isSelected
                      ? null
                      : Border.all(color: context.hairline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : context.descriptionText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  onSubmitted: (_) => _addCustomTag(),
                  style: const TextStyle(fontSize: 14),
                  cursorColor: context.accent,
                  decoration: InputDecoration(
                    hintText: widget.hint ?? 'Add custom tag...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: context.placeholderText,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addCustomTag,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: context.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
