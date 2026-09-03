import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/clip_item.dart';
import '../models/enums.dart';
import '../models/snippet.dart';
import '../repositories/clipboard_repository.dart';
import '../repositories/snippet_repository.dart';
import '../services/clipboard_service.dart';
import '../services/hotkey_service.dart';
import '../services/settings_service.dart';
import '../services/tray_service.dart';
import '../services/window_service.dart';

enum AppSection { history, pinned, snippets, settings }

/// Central, app-wide state. Screens read from this via Provider and call
/// its methods rather than talking to repositories/services directly.
class AppState extends ChangeNotifier {
  AppState({
    ClipboardRepository? clipboardRepository,
    SnippetRepository? snippetRepository,
  })  : clipboardRepo = clipboardRepository ?? ClipboardRepository(),
        snippetRepo = snippetRepository ?? SnippetRepository();

  final ClipboardRepository clipboardRepo;
  final SnippetRepository snippetRepo;

  ClipboardService? _clipboardService;
  TrayService? _trayService;
  final HotkeyService _hotkeyService = HotkeyService.instance;
  final WindowService _windowService = WindowService.instance;
  final SettingsService _settings = SettingsService.instance;

  Timer? _retentionTimer;

  // ---- UI state ----
  AppSection section = AppSection.history;
  List<ClipItem> clips = [];
  List<Snippet> snippets = [];
  ClipCategory? categoryFilter;
  String searchQuery = '';
  bool isPopupMode = false;
  String popupSearchQuery = '';
  int popupSelectedIndex = 0;

  bool monitoringPaused = false;
  bool clipboardMonitoringHealthy = true;
  bool hotkeyHealthy = true;
  bool trayHealthy = true;
  RetentionPolicy retentionPolicy = RetentionPolicy.sevenDays;
  String themeMode = 'system';
  bool isLoading = true;
  String? lastError;

  Future<void> init() async {
    try {
      monitoringPaused = await _settings.isMonitoringPaused();
      retentionPolicy = await _settings.getRetentionPolicy();
      themeMode = await _settings.getThemeMode();

      await _windowService.init();

      _clipboardService = ClipboardService(onNewClip: _handleNewClip);
      await _clipboardService!.start();
      clipboardMonitoringHealthy = _clipboardService!.isRunning;
      if (monitoringPaused) _clipboardService!.pause();

      final hkOk = await _hotkeyService.registerQuickPasteHotkey(
        onTrigger: toggleQuickPastePopup,
      );
      hotkeyHealthy = hkOk;

      _trayService = TrayService(
        onOpen: showMainWindow,
        onTogglePause: toggleMonitoring,
        onOpenSettings: () {
          showMainWindow();
          section = AppSection.settings;
          notifyListeners();
        },
        onClearHistory: () => clearHistory(),
        onExit: exitApp,
      );
      await _trayService!.init();
      trayHealthy = _trayService!.isInitialized;
      await _trayService!.setPausedState(monitoringPaused);

      await applyRetentionCleanup();
      _retentionTimer = Timer.periodic(
        const Duration(hours: 6),
        (_) => applyRetentionCleanup(),
      );

      await refreshClips();
      await refreshSnippets();
    } catch (e, st) {
      developer.log('AppState init failed', name: 'ClipHold.App', error: e, stackTrace: st);
      lastError = 'Something went wrong while starting ClipHold.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Clipboard capture ----------------

  Future<void> _handleNewClip(String content) async {
    try {
      await clipboardRepo.captureClip(content);
      if (!isPopupMode) {
        await refreshClips();
      }
    } catch (e) {
      developer.log('Failed to capture clip', name: 'ClipHold.App', error: e);
    }
  }

  // ---------------- Data loading ----------------

  Future<void> refreshClips() async {
    try {
      clips = await clipboardRepo.getAll(
        category: categoryFilter,
        searchQuery: searchQuery,
      );
      lastError = null;
    } catch (e) {
      developer.log('Failed to load clips', name: 'ClipHold.App', error: e);
      lastError = 'Could not load your clipboard history.';
    }
    notifyListeners();
  }

  Future<void> refreshSnippets() async {
    try {
      snippets = await snippetRepo.getAll();
    } catch (e) {
      developer.log('Failed to load snippets', name: 'ClipHold.App', error: e);
    }
    notifyListeners();
  }

  List<ClipItem> get pinnedClips => clips.where((c) => c.pinned).toList();

  // ---------------- Navigation / filters ----------------

  void setSection(AppSection s) {
    section = s;
    notifyListeners();
  }

  void setCategoryFilter(ClipCategory? category) {
    categoryFilter = category;
    unawaited(refreshClips());
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    unawaited(refreshClips());
  }

  // ---------------- Clip actions ----------------

  Future<void> pinClip(String id, bool pinned) async {
    await clipboardRepo.setPinned(id, pinned);
    await refreshClips();
  }

  Future<void> deleteClip(String id) async {
    await clipboardRepo.delete(id);
    await refreshClips();
  }

  Future<void> updateClipCategory(String id, ClipCategory category) async {
    await clipboardRepo.updateCategory(id, category);
    await refreshClips();
  }

  Future<void> updateClipContent(String id, String content) async {
    await clipboardRepo.updateContent(id, content);
    await refreshClips();
  }

  Future<bool> copyBack(String content) => ClipboardService.writeToClipboard(content);

  Future<void> clearHistory() async {
    await clipboardRepo.clearAll(keepPinned: true);
    await refreshClips();
  }

  Future<void> applyRetentionCleanup() async {
    try {
      await clipboardRepo.applyRetention(retentionPolicy);
      await refreshClips();
    } catch (e) {
      developer.log('Retention cleanup failed', name: 'ClipHold.App', error: e);
    }
  }

  // ---------------- Snippet actions ----------------

  Future<void> createSnippet({
    required String name,
    required String content,
    required ClipCategory category,
    String? shortcut,
  }) async {
    await snippetRepo.create(name: name, content: content, category: category, shortcut: shortcut);
    await refreshSnippets();
  }

  Future<void> updateSnippet(Snippet snippet) async {
    await snippetRepo.update(snippet);
    await refreshSnippets();
  }

  Future<void> deleteSnippet(String id) async {
    await snippetRepo.delete(id);
    await refreshSnippets();
  }

  Future<void> pinSnippet(String id, bool pinned) async {
    await snippetRepo.setPinned(id, pinned);
    await refreshSnippets();
  }

  // ---------------- Monitoring control ----------------

  Future<void> toggleMonitoring() async {
    monitoringPaused = !monitoringPaused;
    if (monitoringPaused) {
      _clipboardService?.pause();
    } else {
      _clipboardService?.resume();
    }
    await _settings.setMonitoringPaused(monitoringPaused);
    await _trayService?.setPausedState(monitoringPaused);
    notifyListeners();
  }

  // ---------------- Settings ----------------

  Future<void> setRetentionPolicy(RetentionPolicy policy) async {
    retentionPolicy = policy;
    await _settings.setRetentionPolicy(policy);
    await applyRetentionCleanup();
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
    await _settings.setThemeMode(mode);
    notifyListeners();
  }

  // ---------------- Window / popup control ----------------

  Future<void> showMainWindow() async {
    isPopupMode = false;
    await _windowService.showMainWindow();
    notifyListeners();
  }

  Future<void> toggleQuickPastePopup() async {
    if (isPopupMode) {
      await closeQuickPastePopup();
    } else {
      await openQuickPastePopup();
    }
  }

  Future<void> openQuickPastePopup() async {
    isPopupMode = true;
    popupSearchQuery = '';
    popupSelectedIndex = 0;
    await refreshClips();
    await _windowService.showQuickPastePopup();
    notifyListeners();
  }

  Future<void> closeQuickPastePopup() async {
    isPopupMode = false;
    await _windowService.hidePopup();
    notifyListeners();
  }

  void setPopupSearchQuery(String query) {
    popupSearchQuery = query;
    popupSelectedIndex = 0;
    unawaited(refreshPopupResults());
  }

  Future<void> refreshPopupResults() async {
    try {
      clips = await clipboardRepo.getAll(searchQuery: popupSearchQuery, limit: 50);
    } catch (e) {
      developer.log('Popup search failed', name: 'ClipHold.App', error: e);
    }
    notifyListeners();
  }

  void movePopupSelection(int delta) {
    if (clips.isEmpty) return;
    popupSelectedIndex = (popupSelectedIndex + delta).clamp(0, clips.length - 1);
    notifyListeners();
  }

  Future<void> selectPopupItem() async {
    if (clips.isEmpty || popupSelectedIndex >= clips.length) return;
    final item = clips[popupSelectedIndex];
    await copyBack(item.content);
    await closeQuickPastePopup();
  }

  Future<void> hideWindowToTray() => _windowService.hideToTray();

  Future<void> exitApp() async {
    _retentionTimer?.cancel();
    await _hotkeyService.unregisterAll();
    await _trayService?.dispose();
    await _clipboardService?.stop();
    await _windowService.exitApp();
  }

  @override
  void dispose() {
    _retentionTimer?.cancel();
    super.dispose();
  }
}
