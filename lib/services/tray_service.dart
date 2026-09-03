import 'dart:developer' as developer;

import 'package:tray_manager/tray_manager.dart';

/// Real Windows system tray integration via `tray_manager` (native tray
/// icon + native right-click menu, not a custom-drawn overlay).
class TrayService with TrayListener {
  TrayService({
    required this.onOpen,
    required this.onTogglePause,
    required this.onOpenSettings,
    required this.onClearHistory,
    required this.onExit,
  });

  final void Function() onOpen;
  final void Function() onTogglePause;
  final void Function() onOpenSettings;
  final void Function() onClearHistory;
  final void Function() onExit;

  bool _initialized = false;
  bool _paused = false;

  Future<void> init() async {
    try {
      trayManager.addListener(this);
      // NOTE: replace with a real .ico bundled at windows/runner/resources/
      // for the production build (see WINDOWS_CONFIG.md).
      await trayManager.setIcon('assets/icons/tray_icon.ico');
      await trayManager.setToolTip('ClipHold — Your clipboard. Remembered. Private.');
      await _rebuildMenu();
      _initialized = true;
    } catch (e) {
      developer.log('Tray init failed', name: 'ClipHold.Tray', error: e);
      _initialized = false;
    }
  }

  bool get isInitialized => _initialized;

  Future<void> setPausedState(bool paused) async {
    _paused = paused;
    if (_initialized) await _rebuildMenu();
  }

  Future<void> _rebuildMenu() async {
    final menu = Menu(
      items: [
        MenuItem(key: 'open', label: 'Open ClipHold'),
        MenuItem.separator(),
        _paused
            ? MenuItem(key: 'resume', label: 'Resume Monitoring')
            : MenuItem(key: 'pause', label: 'Pause Monitoring'),
        MenuItem(key: 'settings', label: 'Settings'),
        MenuItem.separator(),
        MenuItem(key: 'clear', label: 'Clear History'),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    // Left-click on the tray icon opens ClipHold, matching Windows norms.
    onOpen();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        onOpen();
        break;
      case 'pause':
      case 'resume':
        onTogglePause();
        break;
      case 'settings':
        onOpenSettings();
        break;
      case 'clear':
        onClearHistory();
        break;
      case 'exit':
        onExit();
        break;
    }
  }

  Future<void> dispose() async {
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e) {
      developer.log('Tray destroy failed', name: 'ClipHold.Tray', error: e);
    }
  }
}
