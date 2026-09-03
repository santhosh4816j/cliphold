import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/quick_paste_popup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClipHoldApp());
}

class ClipHoldApp extends StatelessWidget {
  const ClipHoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const _ClipHoldRoot(),
    );
  }
}

class _ClipHoldRoot extends StatefulWidget {
  const _ClipHoldRoot();

  @override
  State<_ClipHoldRoot> createState() => _ClipHoldRootState();
}

class _ClipHoldRootState extends State<_ClipHoldRoot> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  /// Clicking the window's X button hides ClipHold to the tray instead of
  /// terminating the process — the app keeps monitoring the clipboard in
  /// the background, matching standard clipboard-manager behavior.
  @override
  void onWindowClose() async {
    final app = context.read<AppState>();
    if (app.isPopupMode) {
      await app.closeQuickPastePopup();
    } else {
      await app.hideWindowToTray();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return MaterialApp(
      title: 'ClipHold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (app.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: app.isLoading
          ? const _SplashView()
          : (app.isPopupMode ? const QuickPastePopup() : const HomeShell()),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.content_paste_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('ClipHold', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Your clipboard. Remembered. Private.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
