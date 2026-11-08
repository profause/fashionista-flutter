/// Who can see a trend post.
enum TrendAudience {
  /// Anyone signed in sees the post in the feed and can join the trend.
  public('public'),

  /// Only the author sees it: the public feed excludes drafts.
  draft('draft');

  const TrendAudience(this.value);

  /// Stored value in Firestore/Hive.
  final String value;

  /// Unknown or missing values (older documents) count as public.
  static TrendAudience fromValue(String? value) =>
      value == draft.value ? draft : public;

  String get label => switch (this) {
    TrendAudience.public => 'Public',
    TrendAudience.draft => 'Draft',
  };

  String get description => switch (this) {
    TrendAudience.public => 'Anyone can see and join this trend',
    TrendAudience.draft => 'Only you can see this post for now',
  };
}
