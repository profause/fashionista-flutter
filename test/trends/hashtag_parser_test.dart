import 'package:fashionista/core/utils/hashtag_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeHashtag', () {
    test('finds the token at the caret', () {
      const text = 'summer #linen vibes';
      final active = activeHashtag(
        text,
        const TextSelection.collapsed(offset: 12),
      );

      expect(active, isNotNull);
      expect(active!.start, 7);
      expect(active.end, 13);
      expect(active.query, 'linen');
    });

    test('extends to the token end when the caret is mid-token', () {
      const text = '#summer style';
      final active = activeHashtag(
        text,
        const TextSelection.collapsed(offset: 4),
      );

      expect(active!.start, 0);
      expect(active.end, 7);
      expect(active.query, 'summer');
    });

    test('returns an empty query right after #', () {
      final active = activeHashtag(
        '#',
        const TextSelection.collapsed(offset: 1),
      );

      expect(active, isNotNull);
      expect(active!.query, isEmpty);
    });

    test('is null once whitespace ends the token', () {
      expect(
        activeHashtag('#linen ', const TextSelection.collapsed(offset: 7)),
        isNull,
      );
    });

    test('ignores a # inside a word', () {
      expect(
        activeHashtag('email#tag', const TextSelection.collapsed(offset: 9)),
        isNull,
      );
    });

    test('strips trailing punctuation from the query', () {
      final active = activeHashtag(
        'a #linen.',
        const TextSelection.collapsed(offset: 9),
      );

      expect(active!.query, 'linen');
    });
  });

  group('extractHashtags', () {
    test('returns every hashtag in order', () {
      expect(extractHashtags('A #summer look with #linen and #summer again'), [
        'summer',
        'linen',
      ]);
    });

    test('ignores trailing punctuation and word-internal hashes', () {
      expect(extractHashtags('a #trend, email#tag and #style!'), [
        'trend',
        'style',
      ]);
    });

    test('keeps hyphens', () {
      expect(extractHashtags('#crop-top'), ['crop-top']);
    });

    test('returns nothing for a bare hash', () {
      expect(extractHashtags('#'), isEmpty);
    });

    test('keeps the exact spelling of known interest names', () {
      expect(
        extractHashtags(
          '#OfficeChic and #Lace, then #officechic again',
          knownTags: ['OfficeChic', 'Lace'],
        ),
        ['OfficeChic', 'Lace'],
      );
    });

    test('matches a multi-word interest name as one tag', () {
      expect(
        extractHashtags(
          'a #Crop Top look and #Lace',
          knownTags: ['Crop Top', 'Lace'],
        ),
        ['Crop Top', 'Lace'],
      );
    });

    test('falls back to the typed token for unknown hashtags', () {
      expect(extractHashtags('#crop top'), ['crop']);
    });
  });

  group('hashtagFor', () {
    test('keeps the exact interest name and case', () {
      expect(hashtagFor('Crop Top'), 'Crop Top');
      expect(hashtagFor('OfficeChic'), 'OfficeChic');
    });

    test('strips hashes and commas', () {
      expect(hashtagFor('#Y2K,'), 'Y2K');
      expect(hashtagFor('denim, blue'), 'denim blue');
    });

    test('keeps hyphens and trims edges', () {
      expect(hashtagFor(' co-ord '), 'co-ord');
      expect(hashtagFor('-denim-'), '-denim-');
    });

    test('returns empty when nothing usable remains', () {
      expect(hashtagFor('   '), isEmpty);
      expect(hashtagFor('...'), isEmpty);
    });
  });

  group('insertHashtag', () {
    test('replaces the active token', () {
      const text = 'I love #sum';
      final active = activeHashtag(
        text,
        const TextSelection.collapsed(offset: text.length),
      );

      final insertion = insertHashtag(
        text: text,
        selection: const TextSelection.collapsed(offset: 11),
        hashtag: 'summer',
        active: active,
      );

      expect(insertion.text, 'I love #summer ');
      expect(insertion.selection.baseOffset, insertion.text.length);
    });

    test('inserts at the caret with a separating space', () {
      final insertion = insertHashtag(
        text: 'Hello',
        selection: const TextSelection.collapsed(offset: 5),
        hashtag: 'linen',
      );

      expect(insertion.text, 'Hello #linen ');
      expect(insertion.selection.baseOffset, insertion.text.length);
    });

    test('inserts into an empty description', () {
      final insertion = insertHashtag(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
        hashtag: 'linen',
      );

      expect(insertion.text, '#linen ');
      expect(insertion.selection.baseOffset, 7);
    });

    test('replaces a token in the middle of a sentence', () {
      const text = '#sum is nice';
      final active = activeHashtag(
        text,
        const TextSelection.collapsed(offset: 4),
      );

      final insertion = insertHashtag(
        text: text,
        selection: const TextSelection.collapsed(offset: 4),
        hashtag: 'summer',
        active: active,
      );

      expect(insertion.text, '#summer is nice');
    });

    test('inserts the exact multi-word interest name', () {
      final insertion = insertHashtag(
        text: 'x',
        selection: const TextSelection.collapsed(offset: 1),
        hashtag: 'Crop Top',
      );

      expect(insertion.text, 'x #Crop Top ');
    });
  });
}
