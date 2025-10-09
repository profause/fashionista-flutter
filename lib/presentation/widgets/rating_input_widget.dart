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
    _rating = widget.initialRating;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RatingInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      setState(() {
        _rating = widget.initialRating;
      });
    }
  }

  void _updateRating(double newRating) {
    if (widget.readOnly) return;
    setState(() => _rating = newRating);
    widget.onChanged?.call(newRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starIndex = index + 1;

        // full-star display only (no half)
        final star = Icon(
          _rating >= starIndex ? Icons.star : Icons.star_border,
          color: widget.color,
          size: widget.size,
        );

        if (widget.readOnly) return star;

        return GestureDetector(
          onTap: () => _updateRating(starIndex.toDouble()),
          child: star,
        );
      }),
    );
  }
}
