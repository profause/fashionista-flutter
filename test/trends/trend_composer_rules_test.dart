import 'package:fashionista/presentation/screens/trends/trend_composer_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendComposerRules.canPublish', () {
    test('blocks publishing without media', () {
      expect(
        TrendComposerRules.canPublish(
          description: 'Summer linen look',
          hasMedia: false,
          isUploading: false,
        ),
        isFalse,
      );
    });

    test('blocks publishing with a blank description', () {
      expect(
        TrendComposerRules.canPublish(
          description: '   ',
          hasMedia: true,
          isUploading: false,
        ),
        isFalse,
      );
    });

    test('blocks publishing while an upload runs', () {
      expect(
        TrendComposerRules.canPublish(
          description: 'Summer linen look',
          hasMedia: true,
          isUploading: true,
        ),
        isFalse,
      );
    });

    test('allows publishing with media and a description', () {
      expect(
        TrendComposerRules.canPublish(
          description: 'Summer linen look',
          hasMedia: true,
          isUploading: false,
        ),
        isTrue,
      );
    });
  });
}
