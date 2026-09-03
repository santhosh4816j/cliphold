# ClipHold — Manual QA Checklist (Windows)

Run through this after every significant change, and before any release
build. Check items in order; later sections assume earlier ones pass.

## Clipboard capture
- [ ] Copy plain text (Ctrl+C) in Notepad → appears in History within ~1s
- [ ] Copy a URL → auto-categorized as "Links"
- [ ] Copy a code snippet (e.g. a few lines of JS/Python/SQL) → auto-categorized as "Code"
- [ ] Copy the same text 5 times in a row → only ONE row in History, with a ×5 badge, not 5 rows
- [ ] Copy a very large block of text (>50,000 characters) → captured without freezing the UI
- [ ] Copy an empty selection / press Ctrl+C with nothing selected → no crash, no blank entry created
- [ ] Copy non-text content (e.g. an image in Paint) → app does not crash; no garbage text entry appears

## Search
- [ ] Search box filters History as you type
- [ ] Search matches on partial words
- [ ] Search with no matches shows a sensible empty state, not a blank screen
- [ ] Clearing the search restores the full list

## Categories
- [ ] Category filter chips (All/Text/Links/Code) correctly filter the grid
- [ ] Manually changing a clip's category (via Edit) persists after app restart

## Pinning
- [ ] Pin a clip → it appears in the Pinned tab
- [ ] Unpin → it disappears from Pinned but remains in History
- [ ] Pinned clips are visually marked (pin icon) in History too

## Copy back
- [ ] Clicking a clip's Copy button places its content on the Windows clipboard
- [ ] Immediately pasting (Ctrl+V) into Notepad reproduces the exact original text
- [ ] Copy-back on a pinned clip works identically

## Edit / Delete
- [ ] Editing a clip's text and saving updates it in place (no duplicate row)
- [ ] Deleting a clip removes it immediately, no restart needed
- [ ] Deleted clips do not reappear after app restart

## Snippets
- [ ] Create a snippet with name + content + optional shortcut label
- [ ] Snippet appears in Snippets tab
- [ ] Edit a snippet, verify changes persist after restart
- [ ] Delete a snippet, verify it's gone after restart
- [ ] Pin a snippet, verify it sorts to the top

## Quick Paste popup (Alt+V)
- [ ] Press Alt+V from ANY other focused app (e.g. Notepad, browser) → compact popup appears
- [ ] Popup search field is focused immediately (can type without clicking)
- [ ] Typing filters results live
- [ ] Arrow Up/Down moves the highlighted selection
- [ ] Enter copies the selected item back to clipboard and closes the popup
- [ ] Escape closes the popup without copying anything
- [ ] Clicking a result with the mouse also copies it and closes the popup
- [ ] After the popup closes, pasting (Ctrl+V) into the previously-focused app works
- [ ] Popup reopens correctly a second/third time (no leftover state bugs)

## System tray
- [ ] ClipHold icon appears in the system tray on launch
- [ ] Left-click tray icon → opens/focuses the main window
- [ ] Right-click tray icon → shows menu: Open ClipHold, Pause/Resume Monitoring, Settings, Clear History, Exit
- [ ] "Pause Monitoring" from tray stops new capture (verify by copying something after pausing — it should NOT appear)
- [ ] "Resume Monitoring" from tray resumes capture
- [ ] "Clear History" from tray clears unpinned items as expected
- [ ] "Exit" from tray fully terminates the process (check Task Manager)

## Window behavior
- [ ] Clicking the main window's X button hides it to tray — process keeps running (check Task Manager)
- [ ] Clipboard monitoring continues working while hidden to tray
- [ ] Reopening from tray restores the window at a sensible size/position

## Pause / Resume (from Settings too)
- [ ] Settings toggle mirrors tray pause/resume state (stay in sync both directions)
- [ ] Paused state persists across app restart

## Retention
- [ ] Set retention to "1 day", confirm setting persists after restart
- [ ] Old unpinned clips are removed after the retention window elapses
- [ ] Pinned clips are NEVER removed by retention, regardless of age
- [ ] "Never" retention setting disables automatic cleanup entirely

## Persistence across restarts
- [ ] Close ClipHold fully (Exit from tray), reopen → all history, pins, and snippets are intact
- [ ] Restart Windows itself → ClipHold data still intact on next launch

## Theming
- [ ] Light mode renders correctly (no unreadable text, no clipped layouts)
- [ ] Dark mode renders correctly
- [ ] "System" theme mode follows the OS light/dark setting

## Error resilience
- [ ] If the global hotkey fails to register (simulate by having another app bind Alt+V first), Settings shows a warning instead of the app crashing
- [ ] If tray icon fails to initialize (rare), the app still opens as a normal window
- [ ] Corrupting/deleting the local DB file, then launching ClipHold, does not crash the whole app (should show an error state, not a blank screen)

## Performance
- [ ] With 500+ clips in history, scrolling the grid stays smooth
- [ ] With 500+ clips, search still returns results quickly (under ~200ms perceived)
- [ ] CPU usage is near-idle when the app is sitting in the tray doing nothing
