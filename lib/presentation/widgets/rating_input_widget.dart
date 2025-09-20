import 'package:flutter/material.dart';

class RatingInputWidget extends StatefulWidget {
  final double initialRating;
  final int maxRating;
  final Color color;
  final double size;
  final ValueChanged<double>? onChanged;
  final bool readOnly;

  const RatingInputWidget({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.color = Colors.amber,
    this.size = 28,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<RatingInputWidget> createState() => _RatingInputWidgetState();
}

class _RatingInputWidgetState extends State<RatingInputWidget> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _updateRating(double newRating) {
    if (widget.readOnly) return; // 🔒 Prevent changes
    setState(() => _rating = newRating);
    if (widget.onChanged != null) widget.onChanged!(newRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starIndex = index + 1;

        Widget star = Icon(
          _rating >= starIndex
              ? Icons.star
              : (_rating >= starIndex - 0.5
                  ? Icons.star_half
                  : Icons.star_border),
          color: widget.color,
          size: widget.size,
        );

        if (widget.readOnly) {
          return star; // Just display, no interaction
        }

        return GestureDetector(
          onTapDown: (details) {
            //final box = context.findRenderObject() as RenderBox;
            final localX = details.localPosition.dx;
            final starWidth = widget.size;

            // Tap left half = 0.5, right half = full star
            if (localX < starWidth / 2) {
              _updateRating(starIndex - 0.5);
            } else {
              _updateRating(starIndex.toDouble());
            }
          },
          child: star,
        );
      }),
    );
  }
}
