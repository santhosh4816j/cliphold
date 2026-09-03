import 'package:flutter/material.dart';

import '../models/clip_item.dart';
import '../models/enums.dart';
import '../utils/ui_helpers.dart';

class ClipboardCard extends StatelessWidget {
  const ClipboardCard({
    super.key,
    required this.item,
    required this.onCopy,
    required this.onPin,
    required this.onDelete,
    required this.onEdit,
  });

  final ClipItem item;
  final VoidCallback onCopy;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(categoryIcon(item.category.label),
                        size: 15, color: scheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.category.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: scheme.outlineVariant)),
                  const SizedBox(width: 8),
                  Text(
                    formatRelativeTime(item.updatedAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (item.copyCount > 1) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('×${item.copyCount}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                  const Spacer(),
                  if (item.pinned)
                    Icon(Icons.push_pin_rounded, size: 15, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: item.category.label == 'Code' ? 'Consolas' : null,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copy back',
                    onPressed: onCopy,
                  ),
                  _ActionButton(
                    icon: item.pinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    tooltip: item.pinned ? 'Unpin' : 'Pin',
                    onPressed: onPin,
                    active: item.pinned,
                  ),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    danger: true,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? color;
    if (danger) color = scheme.error.withValues(alpha: 0.85);
    if (active) color = scheme.primary;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      ),
    );
  }
}
