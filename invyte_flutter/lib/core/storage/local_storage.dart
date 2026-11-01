import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key-value persistence backed by [SharedPreferences].
///
/// Credentials never go here; see `TokenStore` (secure storage).
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _kUser = 'session.user';
  static const _kDemo = 'session.demo';
  static const _kOnboarded = 'app.onboarded';
  static const _kThemeMode = 'app.theme_mode';
  static const _kRecentSearches = 'app.recent_searches';

  // ---- Session ----
  bool get isDemo => _prefs.getBool(_kDemo) ?? false;

  Map<String, dynamic>? get userJson {
    final raw = _prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession({required Map<String, dynamic> user, required bool demo}) async {
    await _prefs.setString(_kUser, jsonEncode(user));
    await _prefs.setBool(_kDemo, demo);
  }

  Future<void> saveUser(Map<String, dynamic> user) => _prefs.setString(_kUser, jsonEncode(user));

  Future<void> clearSession() async {
    await _prefs.remove(_kUser);
    await _prefs.remove(_kDemo);
  }

  // ---- App preferences ----
  bool get hasOnboarded => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_kThemeMode),
        orElse: () => ThemeMode.system,
      );

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_kThemeMode, mode.name);

  List<String> get recentSearches => _prefs.getStringList(_kRecentSearches) ?? const [];

  Future<void> addRecentSearch(String term) {
    final updated = [term, ...recentSearches.where((t) => t != term)].take(6).toList();
    return _prefs.setStringList(_kRecentSearches, updated);
  }
}
