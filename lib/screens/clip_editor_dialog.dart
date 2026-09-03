import 'package:flutter/material.dart';

import '../models/clip_item.dart';
import '../models/enums.dart';
import '../providers/app_state.dart';

Future<void> showClipEditorDialog(
  BuildContext context,
  AppState app,
  ClipItem item,
) async {
  final controller = TextEditingController(text: item.content);
  ClipCategory category = item.category;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Edit clip'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 8,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Clip content',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
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
                final newContent = controller.text;
                if (newContent.trim().isNotEmpty && newContent != item.content) {
                  await app.updateClipContent(item.id, newContent);
                }
                if (category != item.category) {
                  await app.updateClipCategory(item.id, category);
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
