/// Publishing rules for the trends composer.
///
/// Kept free of widget imports so the rules can be unit tested without
/// booting the screen.
class TrendComposerRules {
  TrendComposerRules._();

  /// Whether the composer has everything a trend needs to be published.
  ///
  /// A trend is a look: the feed card renders media, so a post without at
  /// least one photo or video would fall back to the "no image" placeholder.
  static bool canPublish({
    required String description,
    required bool hasMedia,
    required bool isUploading,
  }) {
    if (isUploading) return false;
    if (!hasMedia) return false;
    return description.trim().isNotEmpty;
  }
}
