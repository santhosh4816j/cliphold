import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/app_state.dart';
import '../utils/ui_helpers.dart';

/// The compact overlay shown when the user presses Alt+V. Rendered as the
/// full content of the (resized, frameless, always-on-top) native window
/// in popup mode — see WindowService.
class QuickPastePopup extends StatefulWidget {
  const QuickPastePopup({super.key});

  @override
  State<QuickPastePopup> createState() => _QuickPastePopupState();
}

class _QuickPastePopupState extends State<QuickPastePopup> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleKey(AppState app, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      app.closeQuickPastePopup();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      app.movePopupSelection(1);
      _scrollToSelection(app);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      app.movePopupSelection(-1);
      _scrollToSelection(app);
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      app.selectPopupItem();
    }
  }

  void _scrollToSelection(AppState app) {
    // Simple approximate scroll: each card ~ 70px tall.
    final target = app.popupSelectedIndex * 72.0;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final items = app.clips;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKey(app, event),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _PopupHeader(onClose: app.closeQuickPastePopup),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: app.setPopupSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search clips… (↑↓ to navigate, Enter to paste)',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.content_paste_off_rounded,
                      title: 'No clips found',
                      message: 'Copy something with Ctrl+C, it will show up here.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = index == app.popupSelectedIndex;
                        return _PopupItemTile(
                          content: item.preview,
                          categoryLabel: item.category.label,
                          pinned: item.pinned,
                          selected: isSelected,
                          onTap: () async {
                            await app.copyBack(item.content);
                            await app.closeQuickPastePopup();
                          },
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Icon(Icons.keyboard_rounded, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Enter to paste · Esc to close',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupHeader extends StatelessWidget {
  const _PopupHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      child: Row(
        children: [
          Icon(Icons.content_paste_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text('ClipHold', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _PopupItemTile extends StatelessWidget {
  const _PopupItemTile({
    required this.content,
    required this.categoryLabel,
    required this.pinned,
    required this.selected,
    required this.onTap,
  });

  final String content;
  final String categoryLabel;
  final bool pinned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(categoryIcon(categoryLabel), size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (pinned) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.push_pin_rounded, size: 13, color: scheme.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
