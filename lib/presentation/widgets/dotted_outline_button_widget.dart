import 'dart:math';
import 'package:flutter/material.dart';

class DottedOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final double height;
  final double? width;
  final TextStyle? textStyle;
  final Color borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;

  const DottedOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 44,
    this.width,
    this.textStyle,
    this.borderColor = Colors.grey,
    this.backgroundColor,
    this.borderRadius = 12,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1.6,
    this.icon,
    this.iconSize = 18,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ?? TextStyle(fontSize: 14, color: borderColor);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: borderColor,
          strokeWidth: strokeWidth,
          radius: borderRadius,
          dashWidth: dashWidth,
          dashGap: dashGap,
        ),
        child: Material(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: iconSize,
                      color: iconColor ?? borderColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: effectiveTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashGap;

  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final currentLength = min(dashWidth, metric.length - distance);
        final segment = metric.extractPath(distance, distance + currentLength);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) {
    return old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.radius != radius ||
        old.dashWidth != dashWidth ||
        old.dashGap != dashGap;
  }
}
