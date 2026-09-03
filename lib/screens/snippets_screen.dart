import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/snippet.dart';
import '../providers/app_state.dart';
import '../utils/ui_helpers.dart';
import '../widgets/search_bar.dart';
import '../widgets/snippet_card.dart';

class SnippetsScreen extends StatefulWidget {
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final filtered = _query.isEmpty
        ? app.snippets
        : app.snippets
            .where((s) =>
                s.name.toLowerCase().contains(_query.toLowerCase()) ||
                s.content.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            children: [
              Text('Snippets', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showEditor(context, app),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New snippet'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppSearchBar(
            hintText: 'Search snippets...',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? EmptyStateView(
                  icon: Icons.bolt_outlined,
                  title: app.snippets.isEmpty ? 'No snippets yet' : 'No matches',
                  message: app.snippets.isEmpty
                      ? 'Create reusable text like signatures, templates, or canned replies.'
                      : 'Try a different search term.',
                  action: app.snippets.isEmpty
                      ? FilledButton.icon(
                          onPressed: () => _showEditor(context, app),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create your first snippet'),
                        )
                      : null,
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 168,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return SnippetCard(
                      snippet: s,
                      onCopy: () async {
                        final ok = await app.copyBack(s.content);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Copied to clipboard' : 'Copy failed'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              width: 240,
                            ),
                          );
                        }
                      },
                      onPin: () => app.pinSnippet(s.id, !s.pinned),
                      onEdit: () => _showEditor(context, app, existing: s),
                      onDelete: () => app.deleteSnippet(s.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEditor(BuildContext context, AppState app, {Snippet? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    final shortcutCtrl = TextEditingController(text: existing?.shortcut ?? '');
    ClipCategory category = existing?.category ?? ClipCategory.text;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(existing == null ? 'New snippet' : 'Edit snippet'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 6,
                    minLines: 3,
                    decoration: const InputDecoration(labelText: 'Content'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: shortcutCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Shortcut (optional)',
                      hintText: 'e.g. ;sig',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Category', style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ClipCategory.values.map((c) {
                      return ChoiceChip(
                        label: Text(c.label),
                        selected: category == c,
                        onSelected: (_) => setState(() => category = c),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final content = contentCtrl.text;
                  if (content.trim().isEmpty) return;
                  if (existing == null) {
                    await app.createSnippet(
                      name: name.isEmpty ? 'Untitled snippet' : name,
                      content: content,
                      category: category,
                      shortcut: shortcutCtrl.text.trim().isEmpty
                          ? null
                          : shortcutCtrl.text.trim(),
                    );
                  } else {
                    await app.updateSnippet(existing.copyWith(
                      name: name.isEmpty ? 'Untitled snippet' : name,
                      content: content,
                      category: category,
                      shortcut: shortcutCtrl.text.trim().isEmpty ? null : shortcutCtrl.text.trim(),
                      clearShortcut: shortcutCtrl.text.trim().isEmpty,
                      updatedAt: DateTime.now(),
                    ));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }
}
