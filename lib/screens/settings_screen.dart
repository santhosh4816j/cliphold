import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),

        _SectionCard(
          title: 'Privacy',
          icon: Icons.lock_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your clipboard stays on this device.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ClipHold stores everything in a local SQLite database on this '
                'PC. Nothing you copy is ever uploaded, synced, or shared. '
                'There are no accounts, no analytics, and no ads.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Monitoring',
          icon: Icons.visibility_outlined,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Capture new clipboard content'),
            subtitle: Text(
              app.monitoringPaused
                  ? 'Paused — new copies will not be saved.'
                  : 'Active — Ctrl+C is being saved automatically.',
            ),
            value: !app.monitoringPaused,
            onChanged: (_) => app.toggleMonitoring(),
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Retention',
          icon: Icons.auto_delete_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Automatically delete unpinned clips after:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RetentionPolicy.values.map((policy) {
                  final selected = app.retentionPolicy == policy;
                  return ChoiceChip(
                    label: Text(policy.label),
                    selected: selected,
                    onSelected: (_) => app.setRetentionPolicy(policy),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Pinned clips are never deleted automatically.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          child: Wrap(
            spacing: 8,
            children: [
              _themeChip(context, app, 'system', 'System'),
              _themeChip(context, app, 'light', 'Light'),
              _themeChip(context, app, 'dark', 'Dark'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Shortcuts',
          icon: Icons.keyboard_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shortcutRow(context, 'Quick paste popup', 'Alt + V'),
              const SizedBox(height: 6),
              if (!app.hotkeyHealthy)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Alt+V could not be registered — another app may be using it.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Data',
          icon: Icons.storage_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${app.clips.length} clips stored locally',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmClear(context, app),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Clear unpinned history'),
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'ClipHold  ·  v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _themeChip(BuildContext context, AppState app, String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: app.themeMode == value,
      onSelected: (_) => app.setThemeMode(value),
    );
  }

  Widget _shortcutRow(BuildContext context, String label, String keys) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(keys, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This removes all unpinned clips permanently. Pinned clips are kept.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              app.clearHistory();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
