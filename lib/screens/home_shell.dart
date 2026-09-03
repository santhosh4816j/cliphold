import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'history_screen.dart';
import 'pinned_screen.dart';
import 'settings_screen.dart';
import 'snippets_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    final screens = {
      AppSection.history: const HistoryScreen(),
      AppSection.pinned: const PinnedScreen(),
      AppSection.snippets: const SnippetsScreen(),
      AppSection.settings: const SettingsScreen(),
    };

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: AppSection.values.indexOf(app.section),
            onDestinationSelected: (i) => app.setSection(AppSection.values[i]),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.content_paste_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.history_rounded),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.push_pin_outlined),
                selectedIcon: Icon(Icons.push_pin_rounded),
                label: Text('Pinned'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt_rounded),
                label: Text('Snippets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(app.section),
                child: screens[app.section]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
