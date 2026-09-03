import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';

/// Persists user preferences locally (SharedPreferences → a small file on
/// disk, never leaves the device).
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _kRetention = 'retention_policy';
  static const _kThemeMode = 'theme_mode'; // system|light|dark
  static const _kMonitoringPaused = 'monitoring_paused';
  static const _kLaunchAtStartup = 'launch_at_startup';
  static const _kMaxHistoryItems = 'max_history_items';
  static const _kHotkeyModifiers = 'hotkey_modifiers';
  static const _kHotkeyKey = 'hotkey_key';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<RetentionPolicy> getRetentionPolicy() async {
    final p = await _p;
    final v = p.getString(_kRetention);
    if (v == null) return RetentionPolicy.sevenDays;
    return RetentionPolicyX.fromDb(v);
  }

  Future<void> setRetentionPolicy(RetentionPolicy policy) async {
    final p = await _p;
    await p.setString(_kRetention, policy.dbValue);
  }

  /// 'system' | 'light' | 'dark'
  Future<String> getThemeMode() async {
    final p = await _p;
    return p.getString(_kThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final p = await _p;
    await p.setString(_kThemeMode, mode);
  }

  Future<bool> isMonitoringPaused() async {
    final p = await _p;
    return p.getBool(_kMonitoringPaused) ?? false;
  }

  Future<void> setMonitoringPaused(bool paused) async {
    final p = await _p;
    await p.setBool(_kMonitoringPaused, paused);
  }

  Future<bool> getLaunchAtStartup() async {
    final p = await _p;
    return p.getBool(_kLaunchAtStartup) ?? false;
  }

  Future<void> setLaunchAtStartup(bool value) async {
    final p = await _p;
    await p.setBool(_kLaunchAtStartup, value);
  }

  Future<int> getMaxHistoryItems() async {
    final p = await _p;
    return p.getInt(_kMaxHistoryItems) ?? 2000;
  }

  Future<void> setMaxHistoryItems(int value) async {
    final p = await _p;
    await p.setInt(_kMaxHistoryItems, value);
  }

  /// Global hotkey configuration, stored as modifier names + logical key
  /// label so it can be re-registered identically across app restarts.
  Future<List<String>> getHotkeyModifiers() async {
    final p = await _p;
    return p.getStringList(_kHotkeyModifiers) ?? ['alt'];
  }

  Future<String> getHotkeyKey() async {
    final p = await _p;
    return p.getString(_kHotkeyKey) ?? 'keyV';
  }

  Future<void> setHotkey({required List<String> modifiers, required String key}) async {
    final p = await _p;
    await p.setStringList(_kHotkeyModifiers, modifiers);
    await p.setString(_kHotkeyKey, key);
  }
}
