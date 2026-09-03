import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const Size kMainWindowSize = Size(1100, 720);
const Size kPopupWindowSize = Size(420, 560);

/// Controls the single native window ClipHold uses for both its full
/// interface and the compact Alt+V quick-paste popup. Using one window in
/// two layouts avoids the added native complexity/fragility of a real
/// multi-window Windows setup while still giving a genuinely separate,
/// frameless, always-on-top popup experience.
class WindowService {
  WindowService._();
  static final WindowService instance = WindowService._();

  bool _isPopupMode = false;
  bool get isPopupMode => _isPopupMode;

  Future<void> init() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: kMainWindowSize,
      minimumSize: Size(760, 520),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'ClipHold',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await windowManager.setPreventClose(true);
  }

  Future<void> showMainWindow() async {
    try {
      _isPopupMode = false;
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      await windowManager.setSize(kMainWindowSize);
      await windowManager.center();
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setResizable(true);
    } catch (e) {
      developer.log('showMainWindow failed', name: 'ClipHold.Window', error: e);
    }
  }

  /// Shows the compact frameless quick-paste popup near the bottom-right
  /// of the primary display (a common, predictable spot for launcher-style
  /// popups on Windows).
  Future<void> showQuickPastePopup() async {
    try {
      _isPopupMode = true;
      await windowManager.setResizable(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
          windowButtonVisibility: false);
      await windowManager.setSize(kPopupWindowSize);
      await _positionPopup();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      developer.log('showQuickPastePopup failed', name: 'ClipHold.Window', error: e);
    }
  }

  Future<void> _positionPopup() async {
    try {
      // window_manager doesn't expose display/work-area geometry directly,
      // so we anchor using the window's own current top-level position as
      // a proxy for "this monitor" and place the popup near its top-right,
      // which reads well on both single- and multi-monitor setups since
      // the window was last shown/centered on the active display.
      final current = await windowManager.getBounds();
      final anchorRight = current.left + current.width;
      final x = anchorRight - kPopupWindowSize.width;
      const y = 80.0;
      await windowManager.setBounds(
        Rect.fromLTWH(x < 0 ? 0 : x, y, kPopupWindowSize.width, kPopupWindowSize.height),
      );
    } catch (e) {
      developer.log('Popup positioning failed, using default', name: 'ClipHold.Window', error: e);
    }
  }

  Future<void> hidePopup() async {
    try {
      if (_isPopupMode) {
        await windowManager.hide();
      }
    } catch (e) {
      developer.log('hidePopup failed', name: 'ClipHold.Window', error: e);
    }
  }

  /// Hides the window to the tray instead of closing the process. Called
  /// when the user clicks the window's X button.
  Future<void> hideToTray() async {
    try {
      await windowManager.hide();
    } catch (e) {
      developer.log('hideToTray failed', name: 'ClipHold.Window', error: e);
    }
  }

  Future<void> exitApp() async {
    try {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
    } catch (e) {
      developer.log('exitApp failed', name: 'ClipHold.Window', error: e);
    } finally {
      exit(0);
    }
  }
}
