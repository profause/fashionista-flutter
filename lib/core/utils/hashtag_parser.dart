import 'package:flutter/services.dart';

/// A `#hashtag` the caret currently sits inside.
class ActiveHashtag {
  /// Index of the leading `#`.
  final int start;

  /// Exclusive index of the token's last character.
  final int end;

  /// Text between `#` and [end], lowercased and without trailing punctuation.
  final String query;

  const ActiveHashtag({
    required this.start,
    required this.end,
    required this.query,
  });
}

/// Result of inserting a hashtag into a description.
class HashtagInsertion {
  final String text;
  final TextSelection selection;

  const HashtagInsertion({required this.text, required this.selection});
}

const Set<String> _trailingPunctuation = {
  '.',
  ',',
  '!',
  '?',
  ';',
  ':',
  ')',
  ']',
  '}',
  '"',
  "'",
};

bool _isBoundary(String char) => char.trim().isEmpty;

String _stripTrailingPunctuation(String value) {
  var end = value.length;
  while (end > 0 && _trailingPunctuation.contains(value[end - 1])) {
    end--;
  }
  return value.substring(0, end);
}

/// Returns the hashtag token the caret is editing, or `null` when the caret is
/// not inside one.
///
/// The returned range covers the whole token, so inserting a replacement can
/// swap `#sum` for `#summer` without leaving fragments behind.
ActiveHashtag? activeHashtag(String text, TextSelection selection) {
  if (text.isEmpty) return null;

  final rawOffset = selection.isValid ? selection.baseOffset : text.length;
  final caret = rawOffset.clamp(0, text.length);

  // A caret directly after whitespace is outside every token.
  if (caret > 0 && _isBoundary(text[caret - 1])) return null;

  var start = -1;
  for (var i = caret - 1; i >= 0; i--) {
    final char = text[i];
    if (_isBoundary(char)) break;
    if (char == '#') {
      start = i;
      break;
    }
  }
  if (start < 0) return null;

  // `#` has to open a word: `email#tag` is not a hashtag.
  if (start > 0 && !_isBoundary(text[start - 1])) return null;

  var end = caret;
  while (end < text.length && !_isBoundary(text[end])) {
    end++;
  }

  final query = _stripTrailingPunctuation(
    text.substring(start + 1, end),
  ).toLowerCase();

  return ActiveHashtag(start: start, end: end, query: query);
}

final RegExp _hashtagPattern = RegExp(r'#([^\s#]+)');

/// Every hashtag in [text], in order of appearance.
///
/// Duplicates are removed case-insensitively and the first spelling is kept.
List<String> extractHashtags(String text) {
  final seen = <String>{};
  final tags = <String>[];

  for (final match in _hashtagPattern.allMatches(text)) {
    if (match.start > 0 && !_isBoundary(text[match.start - 1])) continue;

    final body = _stripTrailingPunctuation(match.group(1) ?? '').trim();
    if (body.isEmpty) continue;
    if (seen.add(body.toLowerCase())) tags.add(body);
  }

  return tags;
}

/// Normalises an interest name into a hashtag body (no leading `#`).
///
/// Hashtags cannot contain spaces or commas, so `Crop Top` becomes `crop-top`.
/// Returns an empty string when nothing usable remains.
String hashtagFor(String name) {
  final buffer = StringBuffer();
  var pendingSeparator = false;

  for (final rune in name.trim().runes) {
    final char = String.fromCharCode(rune);

    if (char == '#' || char == ',' || char == '-' || char.trim().isEmpty) {
      pendingSeparator = true;
      continue;
    }

    final isLetter = char.toLowerCase() != char.toUpperCase();
    final isNumberOrUnderscore = RegExp(r'[0-9_]').hasMatch(char);
    if (!isLetter && !isNumberOrUnderscore) continue;

    if (pendingSeparator && buffer.isNotEmpty) buffer.write('-');
    pendingSeparator = false;
    buffer.write(char.toLowerCase());
  }

  return buffer.toString();
}

/// Inserts [hashtag] at the caret or replaces the [active] token.
///
/// A trailing space is always appended and the caret placed after it, which
/// keeps the interest panel from reopening on the hashtag that was just added.
HashtagInsertion insertHashtag({
  required String text,
  required TextSelection selection,
  required String hashtag,
  ActiveHashtag? active,
}) {
  final body = hashtagFor(hashtag);
  if (body.isEmpty) {
    return HashtagInsertion(text: text, selection: selection);
  }

  final token = '#$body ';

  if (active != null && active.start >= 0 && active.end <= text.length) {
    final before = text.substring(0, active.start);
    var after = text.substring(active.end);

    // The editor already had a separator after the token; reuse it instead of
    // producing a double space.
    if (after.isNotEmpty && _isBoundary(after[0])) {
      after = after.substring(1);
    }

    return HashtagInsertion(
      text: '$before$token$after',
      selection: TextSelection.collapsed(offset: before.length + token.length),
    );
  }

  var start = selection.isValid ? selection.start : text.length;
  var end = selection.isValid ? selection.end : text.length;
  start = start.clamp(0, text.length);
  end = end.clamp(start, text.length);

  final before = text.substring(0, start);
  final after = text.substring(end);
  final prefix = before.isNotEmpty && !_isBoundary(before[before.length - 1])
      ? ' '
      : '';
  final inserted = '$prefix$token';

  return HashtagInsertion(
    text: '$before$inserted$after',
    selection: TextSelection.collapsed(offset: before.length + inserted.length),
  );
}
