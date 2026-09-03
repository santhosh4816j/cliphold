import 'dart:developer' as developer;

import 'package:flutter/services.dart' show PhysicalKeyboardKey;
import 'package:hotkey_manager/hotkey_manager.dart';

/// Registers a real OS-level global hotkey (default Alt+V) that fires even
/// when ClipHold is not focused. Backed by `hotkey_manager`, which uses
/// Windows' RegisterHotKey API under the hood.
class HotkeyService {
  HotkeyService._();
  static final HotkeyService instance = HotkeyService._();

  bool _registered = false;
  HotKey? _current;

  bool get isRegistered => _registered;

  /// Registers the quick-paste hotkey. [onTrigger] is invoked on key-down.
  /// Returns false if registration failed (e.g. key combo already claimed
  /// by another app) so the UI can inform the user instead of silently
  /// pretending it works.
  Future<bool> registerQuickPasteHotkey({
    required void Function() onTrigger,
    List<HotKeyModifier> modifiers = const [HotKeyModifier.alt],
    PhysicalKeyboardKey key = PhysicalKeyboardKey.keyV,
  }) async {
    try {
      await unregisterAll();
      final hotKey = HotKey(
        key: key,
        modifiers: modifiers,
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => onTrigger(),
      );
      _current = hotKey;
      _registered = true;
      return true;
    } catch (e) {
      developer.log('Global hotkey registration failed',
          name: 'ClipHold.Hotkey', error: e);
      _registered = false;
      return false;
    }
  }

  Future<void> unregisterAll() async {
    try {
      await hotKeyManager.unregisterAll();
    } catch (e) {
      developer.log('Failed to unregister hotkeys', name: 'ClipHold.Hotkey', error: e);
    } finally {
      _registered = false;
      _current = null;
    }
  }
}
