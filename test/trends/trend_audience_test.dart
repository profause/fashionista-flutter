import 'package:fashionista/data/models/trends/trend_audience.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../trends/trend_feed_fakes.dart';

void main() {
  group('TrendAudience', () {
    test('only the stored draft value is a draft', () {
      expect(TrendAudience.fromValue('draft'), TrendAudience.draft);
      expect(TrendAudience.fromValue('public'), TrendAudience.public);
    });

    test('a missing value counts as public', () {
      expect(TrendAudience.fromValue(null), TrendAudience.public);
      expect(TrendAudience.fromValue(''), TrendAudience.public);
    });

    test('round-trips through its stored value', () {
      for (final audience in TrendAudience.values) {
        expect(TrendAudience.fromValue(audience.value), audience);
      }
    });
  });

  group('TrendFeedModel.audience', () {
    test('a document written before audiences existed reads as public', () {
      final json = trend('t1').toJson()..remove('audience');

      final model = TrendFeedModel.fromJson(json);

      expect(model.audience, TrendFeedModel.audiencePublic);
      expect(model.isDraft, isFalse);
    });

    test('a draft survives the JSON round trip', () {
      final draft = trend('t2', audience: TrendFeedModel.audienceDraft);

      final decoded = TrendFeedModel.fromJson(draft.toJson());

      expect(decoded.isDraft, isTrue);
      expect(decoded.audience, TrendFeedModel.audienceDraft);
    });

    test('new posts default to public', () {
      expect(TrendFeedModel.empty().isDraft, isFalse);
    });
  });
}
