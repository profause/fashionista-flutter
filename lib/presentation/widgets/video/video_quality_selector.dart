import 'package:fashionista/core/media/cloudinary_video_urls.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Compact SD/HD pill for a playing card.
///
/// Shows the quality in use and switches to the other one on tap. While a
/// switch is running the pill turns into a spinner and stops accepting taps, so
/// repeated requests cannot stack up.
class VideoQualitySelector extends StatelessWidget {
  final VideoQuality quality;
  final bool switching;
  final ValueChanged<VideoQuality> onSelect;

  /// Shown when the rendition URLs cannot be derived (no public id).
  final bool isAvailable;

  const VideoQualitySelector({
    super.key,
    required this.quality,
    required this.onSelect,
    this.switching = false,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) return const SizedBox.shrink();

    final target = quality.other;
    final isHd = quality == VideoQuality.hd;

    return Tooltip(
      message: switching
          ? 'Switching to ${target.label}…'
          : 'Play in ${target.label}',
      child: Material(
        color: Colors.black.withValues(alpha: .45),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: switching ? null : () => onSelect(target),
          child: Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            alignment: Alignment.center,
            child: switching
                ? const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: Colors.white70,
                    ),
                  )
                : Text(
                    quality.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                      color: isHd ? context.accent : Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
