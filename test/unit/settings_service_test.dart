import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cliphold/models/enums.dart';
import 'package:cliphold/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default retention policy is 7 days', () async {
    final policy = await SettingsService.instance.getRetentionPolicy();
    expect(policy, RetentionPolicy.sevenDays);
  });

  test('retention policy round-trips through storage', () async {
    await SettingsService.instance.setRetentionPolicy(RetentionPolicy.thirtyDays);
    final policy = await SettingsService.instance.getRetentionPolicy();
    expect(policy, RetentionPolicy.thirtyDays);
  });

  test('monitoring paused defaults to false', () async {
    final paused = await SettingsService.instance.isMonitoringPaused();
    expect(paused, false);
  });

  test('monitoring paused state round-trips', () async {
    await SettingsService.instance.setMonitoringPaused(true);
    expect(await SettingsService.instance.isMonitoringPaused(), true);
    await SettingsService.instance.setMonitoringPaused(false);
    expect(await SettingsService.instance.isMonitoringPaused(), false);
  });

  test('theme mode defaults to system', () async {
    expect(await SettingsService.instance.getThemeMode(), 'system');
  });

  test('theme mode round-trips', () async {
    await SettingsService.instance.setThemeMode('dark');
    expect(await SettingsService.instance.getThemeMode(), 'dark');
  });

  test('hotkey defaults to Alt+V', () async {
    expect(await SettingsService.instance.getHotkeyModifiers(), ['alt']);
    expect(await SettingsService.instance.getHotkeyKey(), 'keyV');
  });
}
