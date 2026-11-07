import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('autoPlayVideos default', () {
    test('is on for a fresh install', () {
      expect(Settings.empty().autoPlayVideos, isTrue);
      expect(Settings.empty().version, Settings.currentVersion);
    });
  });

  group('migration', () {
    test('upgrades the value persisted by the old default', () {
      // Pre-v2 payload: the stored `false` was the default, not a choice.
      final restored = Settings.fromJson({'autoPlayVideos': false}).migrated();

      expect(restored.autoPlayVideos, isTrue);
      expect(restored.version, Settings.currentVersion);
    });

    test('leaves an explicit off alone once the version is stamped', () {
      final restored = Settings.fromJson({
        'autoPlayVideos': false,
        'settings_version': Settings.currentVersion,
      }).migrated();

      expect(restored.autoPlayVideos, isFalse);
    });

    test('keeps the other settings during the upgrade', () {
      final restored = Settings.fromJson({
        'autoPlayVideos': false,
        'display_mode': 1,
        'image_quality': 'HD',
      }).migrated();

      expect(restored.imageQuality, 'HD');
      expect(restored.displayMode, 1);
    });

    test('preserves an opted-in value', () {
      final restored = Settings.fromJson({'autoPlayVideos': true}).migrated();

      expect(restored.autoPlayVideos, isTrue);
      expect(restored.version, Settings.currentVersion);
    });

    test('a payload without the field gets the new default', () {
      final restored = Settings.fromJson({}).migrated();

      expect(restored.autoPlayVideos, isTrue);
    });
  });
}
