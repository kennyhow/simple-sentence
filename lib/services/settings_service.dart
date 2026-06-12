import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app settings.
class SettingsService {
  static const _keyApiUrl = 'api_url';
  static const _keyApiKey = 'api_key';
  static const _keyModel = 'model';
  static const _keyDeckName = 'deck_name';
  static const _keyModelName = 'anki_model_name';
  static const _keyDefaultTemplate = 'default_template';
  static const _keyThemeMode = 'theme_mode';
  static const _keyMusicEnabled = 'music_enabled';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  /// Expose prefs for services that need direct access (e.g. StreakService).
  SharedPreferences get prefs => _prefs;

  // --- API settings ---

  String get apiUrl =>
      _prefs.getString(_keyApiUrl) ?? 'https://api.openai.com/v1/chat/completions';

  set apiUrl(String value) => _prefs.setString(_keyApiUrl, value);

  String get apiKey => _prefs.getString(_keyApiKey) ?? '';

  set apiKey(String value) => _prefs.setString(_keyApiKey, value);

  String get model => _prefs.getString(_keyModel) ?? 'gpt-4o';

  set model(String value) => _prefs.setString(_keyModel, value);

  bool get isConfigured => apiKey.isNotEmpty && apiUrl.isNotEmpty;

  // --- Anki settings ---

  String get deckName =>
      _prefs.getString(_keyDeckName) ?? 'Japanese Mining';

  set deckName(String value) => _prefs.setString(_keyDeckName, value);

  String get ankiModelName =>
      _prefs.getString(_keyModelName) ?? 'Japanese Sentence';

  set ankiModelName(String value) =>
      _prefs.setString(_keyModelName, value);

  // --- Template settings ---

  String get defaultTemplate =>
      _prefs.getString(_keyDefaultTemplate) ?? 'general';

  set defaultTemplate(String value) =>
      _prefs.setString(_keyDefaultTemplate, value);

  // --- Theme settings ---

  ThemeMode get themeMode {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  set themeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    _prefs.setString(_keyThemeMode, value);
  }

  // --- Music settings ---

  bool get musicEnabled => _prefs.getBool(_keyMusicEnabled) ?? false;

  set musicEnabled(bool value) => _prefs.setBool(_keyMusicEnabled, value);

  /// Template presets that inject context into the LLM prompt.
  static const Map<String, String> templates = {
    'general': '',
    'anime': 'Prefer example sentences from anime/manga contexts.',
    'business': 'Prefer business/formal Japanese contexts.',
    'casual': 'Prefer casual, everyday conversation contexts.',
    'literary': 'Prefer literary/novel contexts.',
    'news': 'Prefer news/article contexts.',
  };

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }
}
