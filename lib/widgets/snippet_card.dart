import 'package:flutter/material.dart';

import '../models/snippet.dart';
import '../utils/ui_helpers.dart';

class SnippetCard extends StatelessWidget {
  const SnippetCard({
    super.key,
    required this.snippet,
    required this.onCopy,
    required this.onPin,
    required this.onEdit,
    required this.onDelete,
  });

  final Snippet snippet;
  final VoidCallback onCopy;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onCopy,
        onDoubleTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      snippet.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (snippet.shortcut != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(snippet.shortcut!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  if (snippet.pinned) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.push_pin_rounded, size: 15, color: scheme.primary),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                snippet.content.replaceAll('\n', ' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onCopy,
                  ),
                  IconButton(
                    tooltip: snippet.pinned ? 'Unpin' : 'Pin',
                    icon: Icon(
                      snippet.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 18,
                    ),
                    color: snippet.pinned ? scheme.primary : null,
                    visualDensity: VisualDensity.compact,
                    onPressed: onPin,
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: scheme.error.withValues(alpha: 0.85),
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
