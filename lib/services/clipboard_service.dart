import 'dart:async';
import 'dart:developer' as developer;

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';

/// Real clipboard monitoring for Windows using [clipboard_watcher], which
/// registers an actual OS-level clipboard-change listener (AddClipboardFormatListener
/// on Windows) rather than polling in a tight loop. Falls back gracefully
/// if the platform listener fails to register.
///
/// PRIVACY: this service never logs clipboard content, only event counts
/// and error types.
class ClipboardService with ClipboardListener {
  ClipboardService({required this.onNewClip});

  /// Called with the freshly-copied text whenever a change is detected
  /// and monitoring is not paused.
  final void Function(String content) onNewClip;

  bool _paused = false;
  bool _started = false;
  String? _lastSeenContent;

  bool get isPaused => _paused;
  bool get isRunning => _started;

  Future<void> start() async {
    if (_started) return;
    try {
      clipboardWatcher.addListener(this);
      await clipboardWatcher.start();
      _started = true;
    } catch (e) {
      developer.log('Clipboard monitoring failed to start',
          name: 'ClipHold.Clipboard', error: e);
      _started = false;
    }
  }

  Future<void> stop() async {
    if (!_started) return;
    try {
      clipboardWatcher.removeListener(this);
      await clipboardWatcher.stop();
    } catch (e) {
      developer.log('Clipboard monitoring failed to stop',
          name: 'ClipHold.Clipboard', error: e);
    } finally {
      _started = false;
    }
  }

  void pause() => _paused = true;
  void resume() => _paused = false;

  @override
  void onClipboardChanged() {
    if (_paused) return;
    unawaited(_handleChange());
  }

  Future<void> _handleChange() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.trim().isEmpty) return;
      // Avoid redundant re-processing when the OS fires multiple change
      // events for the same content (common on some Windows builds).
      if (text == _lastSeenContent) return;
      _lastSeenContent = text;
      onNewClip(text);
    } catch (e) {
      developer.log('Clipboard read failed', name: 'ClipHold.Clipboard', error: e);
    }
  }

  /// Writes content back to the Windows clipboard (Copy Back).
  static Future<bool> writeToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      return true;
    } catch (e) {
      developer.log('Clipboard write failed', name: 'ClipHold.Clipboard', error: e);
      return false;
    }
  }
}
