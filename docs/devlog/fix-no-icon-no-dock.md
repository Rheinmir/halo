# An app you couldn't see: no icon, no Dock tile

*Written 2026-10-14 · Structure: problem*

## How it showed up

Two complaints in a row:

1. "Không có icon cho nó luôn à": Halo appeared with a blank generic icon in the Accessibility list.
2. "Sao bật lên mà mình hông thấy nó trong dock": you couldn't find the app, or its Settings window, from the Dock.

## Why it happened

1. The bundle had no icon at all. The menu bar used a generic system symbol (◎).
2. Halo is built as menu-bar-only (`LSUIElement`). That's right for the ring, but it left the Settings window without a Dock tile or a ⌘Tab entry.

## Fix

- **App icon:** the app draws its own 1024 px icon (a dark rounded square with a ring of colored dots). `build.sh` turns it into a full `.icns` with `sips` and `iconutil`. See [`Icon.swift`](../../Sources/Halo/Icon.swift) and [`build.sh`](../../build.sh).
- **Menu bar:** a custom 18 pt template image instead of the system symbol, so it adapts to light and dark menu bars.
- **Dock only while needed:** opening Settings switches to the `.regular` activation policy, which adds the Dock tile and ⌘Tab entry. Closing it switches back to `.accessory`. Reopening `Halo.app` from Finder brings Settings back.

## Verification

- `NSWorkspace.icon(forFile:)` returns the new icon for `Halo.app`.
- `lsappinfo` reports `Foreground` while Settings is open, `UIElement` after closing it, and `Foreground` again after reopening the app.

## Remaining limits

- System Settings may keep showing an old blank icon from its cache until it's restarted.
- The menu-bar icon couldn't be checked by screenshot, because the terminal lacked Screen Recording permission.
