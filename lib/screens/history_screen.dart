import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/clip_item.dart';
import '../providers/app_state.dart';
import '../utils/ui_helpers.dart';
import '../widgets/category_filter.dart';
import '../widgets/clipboard_card.dart';
import '../widgets/search_bar.dart';
import 'clip_editor_dialog.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.pinnedOnly = false});

  final bool pinnedOnly;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = pinnedOnly ? app.pinnedClips : app.clips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            children: [
              Text(
                pinnedOnly ? 'Pinned' : 'History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (!pinnedOnly && app.monitoringPaused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline_rounded,
                          size: 14, color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Monitoring paused',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              if (!pinnedOnly) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => _confirmClear(context, app),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppSearchBar(
            onChanged: app.setSearchQuery,
            hintText: pinnedOnly
                ? 'Search pinned clips...'
                : 'Search clipboard history...',
          ),
        ),
        if (!pinnedOnly) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CategoryFilterBar(
              selected: app.categoryFilter,
              onSelected: app.setCategoryFilter,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(child: _buildContent(context, app, items)),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppState app, List<ClipItem> items) {
    if (app.isLoading) return const LoadingView(message: 'Loading your history…');
    if (app.lastError != null) {
      return ErrorStateView(message: app.lastError!, onRetry: app.refreshClips);
    }
    if (items.isEmpty) {
      return EmptyStateView(
        icon: pinnedOnly ? Icons.push_pin_outlined : Icons.content_paste_off_rounded,
        title: pinnedOnly ? 'Nothing pinned yet' : 'No clips yet',
        message: pinnedOnly
            ? 'Pin important clips to keep them handy here.'
            : 'Copy something with Ctrl+C — it will appear here automatically.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 168,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ClipboardCard(
          item: item,
          onCopy: () async {
            final ok = await app.copyBack(item.content);
            if (context.mounted) {
              _showCopiedSnack(context, ok);
            }
          },
          onPin: () => app.pinClip(item.id, !item.pinned),
          onDelete: () => app.deleteClip(item.id),
          onEdit: () => showClipEditorDialog(context, app, item),
        );
      },
    );
  }

  void _showCopiedSnack(BuildContext context, bool ok) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Copied to clipboard' : 'Could not copy to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 260,
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This removes all unpinned clips. Pinned clips are kept. This cannot be undone.',
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
