import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'garden.dart';
import 'garden_theme.dart';

/// Owns the persisted garden meta: how many levels have been solved (which
/// drives growth) and which theme is selected. Reactive so the UI updates the
/// moment a level is solved or a theme is chosen.
///
/// The growth and theme *rules* are pure (see [GardenState] and
/// garden_theme.dart); this class only stores state and persists it.
class GardenController extends ChangeNotifier {
  static const String _kSolved = 'garden_levels_solved';
  static const String _kThemeId = 'garden_theme_id';

  int _levelsSolved = 0;
  String _selectedThemeId = kFreeThemeId;

  /// The current garden snapshot.
  GardenState get state => GardenState(levelsSolved: _levelsSolved);

  /// The id the player picked (may be a premium theme they no longer own).
  String get selectedThemeId => _selectedThemeId;

  /// The theme actually rendered, given [premium] — falls back to free if the
  /// selected theme is locked.
  GardenTheme themeFor({required bool premium}) =>
      resolveTheme(_selectedThemeId, premium: premium);

  /// Loads persisted progress. Safe to call once at startup; never throws.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _levelsSolved = prefs.getInt(_kSolved) ?? 0;
      _selectedThemeId = prefs.getString(_kThemeId) ?? kFreeThemeId;
    } catch (_) {
      // Keep defaults on any storage error.
    }
    notifyListeners();
  }

  /// Records a solved level, growing the garden by one step.
  Future<void> recordSolved() async {
    _levelsSolved += 1;
    notifyListeners();
    await _persistInt(_kSolved, _levelsSolved);
  }

  /// Selects a theme, but only if it is unlocked for the given [premium] state.
  /// Returns whether the selection was applied.
  Future<bool> selectTheme(String id, {required bool premium}) async {
    if (!isThemeUnlocked(id, premium: premium)) return false;
    if (id == _selectedThemeId) return true;
    _selectedThemeId = id;
    notifyListeners();
    await _persistString(_kThemeId, id);
    return true;
  }

  Future<void> _persistInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  Future<void> _persistString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }
}
