import 'package:flutter_test/flutter_test.dart';
import 'package:unwind/garden/garden_theme.dart';

void main() {
  group('theme unlocking', () {
    test('the free theme is always unlocked', () {
      expect(isThemeUnlocked(kFreeThemeId, premium: false), isTrue);
      expect(isThemeUnlocked(kFreeThemeId, premium: true), isTrue);
    });

    test('premium themes are locked without premium', () {
      expect(isThemeUnlocked('dusk', premium: false), isFalse);
      expect(isThemeUnlocked('dusk', premium: true), isTrue);
    });

    test('unknown ids are never unlocked', () {
      expect(isThemeUnlocked('nope', premium: true), isFalse);
    });

    test('free players see only free themes; premium sees all', () {
      final free = unlockedThemes(premium: false);
      expect(free.every((t) => !t.isPremium), isTrue);
      expect(free.length, lessThan(kGardenThemes.length));
      expect(unlockedThemes(premium: true).length, kGardenThemes.length);
    });
  });

  group('theme resolution', () {
    test('themeById falls back to the free theme for unknown ids', () {
      expect(themeById('nope').id, kFreeThemeId);
      expect(themeById('dusk').id, 'dusk');
    });

    test('a locked selection resolves to the free theme', () {
      expect(resolveTheme('dusk', premium: false).id, kFreeThemeId);
      expect(resolveTheme('dusk', premium: true).id, 'dusk');
    });

    test('theme ids are unique', () {
      final ids = kGardenThemes.map((t) => t.id).toSet();
      expect(ids.length, kGardenThemes.length);
    });
  });
}
