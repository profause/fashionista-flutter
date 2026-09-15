import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class NotificationTileCard extends StatelessWidget {
  final Widget child;

  const NotificationTileCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class NotificationIconCluster extends StatelessWidget {
  final IconData icon;
  final bool unread;

  const NotificationIconCluster({
    super.key,
    required this.icon,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unread)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: context.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.accent.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          )
        else
          const SizedBox(width: 8),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.iconSubstrate,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: unread ? context.accent : context.onCanvasText,
          ),
        ),
      ],
    );
  }
}

class NotificationTitleRow extends StatelessWidget {
  final String title;
  final String time;

  const NotificationTitleRow({
    super.key,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.onCanvasText,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: context.mutedText,
          ),
        ),
      ],
    );
  }
}

enum NotificationCardButtonStyle { solid, primary, tonal }

class NotificationCardButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final NotificationCardButtonStyle style;

  const NotificationCardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = NotificationCardButtonStyle.solid,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final BorderSide? borderSide;
    final double horizontalPadding;
    final FontWeight fontWeight;

    switch (style) {
      case NotificationCardButtonStyle.solid:
        background = context.onCanvasText;
        foreground = context.isDarkTheme
            ? context.canvasBackground
            : const Color(0xFFFFFFFF);
        borderSide = null;
        horizontalPadding = 14;
        fontWeight = FontWeight.w600;
      case NotificationCardButtonStyle.primary:
        background = context.accent;
        foreground = const Color(0xFFFFFFFF);
        borderSide = null;
        horizontalPadding = 16;
        fontWeight = FontWeight.w600;
      case NotificationCardButtonStyle.tonal:
        background = context.secondaryButtonBg;
        foreground = context.descriptionText;
        borderSide = BorderSide(color: context.hairline);
        horizontalPadding = 14;
        fontWeight = FontWeight.w500;
    }

    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: background,
          foregroundColor: foreground,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: fontWeight,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}