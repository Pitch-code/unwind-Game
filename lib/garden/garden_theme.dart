import 'dart:ui' show Color;

/// A cosmetic palette for the zen garden. One theme is free; the rest are the
/// reward unlocked by the single "Remove Ads + unlock all garden themes"
/// purchase. Pure data (only [Color] from dart:ui), so it is unit-testable
/// without a widget binding.
class GardenTheme {
  const GardenTheme({
    required this.id,
    required this.name,
    required this.isPremium,
    required this.sky,
    required this.soil,
    required this.stem,
    required this.leaf,
    required this.bloom,
  });

  /// Stable id persisted in preferences; never localise or reuse this.
  final String id;

  /// Human-facing name shown in the theme picker.
  final String name;

  /// Whether unlocking this theme requires premium.
  final bool isPremium;

  final Color sky;
  final Color soil;
  final Color stem;
  final Color leaf;
  final Color bloom;
}

/// The id of the one theme available without any purchase.
const String kFreeThemeId = 'meadow';

/// Every theme in the game, free first.
const List<GardenTheme> kGardenThemes = <GardenTheme>[
  GardenTheme(
    id: kFreeThemeId,
    name: 'Meadow',
    isPremium: false,
    sky: Color(0xFF12211B),
    soil: Color(0xFF2A3B32),
    stem: Color(0xFF5E8577),
    leaf: Color(0xFF8FE0C0),
    bloom: Color(0xFFE7C56A),
  ),
  GardenTheme(
    id: 'dusk',
    name: 'Dusk',
    isPremium: true,
    sky: Color(0xFF1A1726),
    soil: Color(0xFF322A45),
    stem: Color(0xFF7A6DA6),
    leaf: Color(0xFFB6A6E6),
    bloom: Color(0xFFF0A6C2),
  ),
  GardenTheme(
    id: 'sakura',
    name: 'Sakura',
    isPremium: true,
    sky: Color(0xFF241A20),
    soil: Color(0xFF3D2A33),
    stem: Color(0xFF8A6E74),
    leaf: Color(0xFFC9A5AC),
    bloom: Color(0xFFF7C9D8),
  ),
  GardenTheme(
    id: 'tide',
    name: 'Tide',
    isPremium: true,
    sky: Color(0xFF0E1E24),
    soil: Color(0xFF1E3A42),
    stem: Color(0xFF4E8C99),
    leaf: Color(0xFF86D0DA),
    bloom: Color(0xFFE9E4A6),
  ),
  GardenTheme(
    id: 'ember',
    name: 'Ember',
    isPremium: true,
    sky: Color(0xFF221512),
    soil: Color(0xFF3D2620),
    stem: Color(0xFF9A5F4A),
    leaf: Color(0xFFD79A72),
    bloom: Color(0xFFF3C15E),
  ),
];

/// The free fallback theme, always present.
GardenTheme get freeTheme =>
    kGardenThemes.firstWhere((t) => t.id == kFreeThemeId);

/// Looks up a theme by id, falling back to the free theme for unknown ids.
GardenTheme themeById(String id) => kGardenThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => freeTheme,
    );

/// Whether the theme [id] is usable given the player's [premium] state.
bool isThemeUnlocked(String id, {required bool premium}) {
  final theme = kGardenThemes.where((t) => t.id == id);
  if (theme.isEmpty) return false;
  return premium || !theme.first.isPremium;
}

/// The themes the player may currently select.
List<GardenTheme> unlockedThemes({required bool premium}) =>
    kGardenThemes.where((t) => premium || !t.isPremium).toList();

/// Resolves the effective theme to render: the [selectedId] if it is unlocked,
/// otherwise the free theme. This keeps the garden correct even if premium is
/// somehow lost after a premium theme was chosen.
GardenTheme resolveTheme(String selectedId, {required bool premium}) =>
    isThemeUnlocked(selectedId, premium: premium)
        ? themeById(selectedId)
        : freeTheme;
