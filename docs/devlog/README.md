# Halo devlog

Notes on problems we hit and features we built, one topic per post. Each post says what we verified and what we didn't.

## Features

- [Building a ring launcher without Xcode](build-ring-launcher.md): why not xtool, the event tap, the delay, the geometry
- [Choosing the exact window from the ring](build-window-picker.md): Accessibility windows, "leave the ring to enter the list"
- [Arranging apps directly on the ring](build-arrange-on-ring.md): drag icons between slots, drop apps from Finder
- [Settings that looked adjustable but weren't](build-trigger-key-and-delay.md): choosable trigger key and delay
- [English and Vietnamese interface](build-bilingual-interface.md): `tr()` strings, English by default, screenshots in both languages
- [One signal for "this slot is selected"](design-single-selection-signal.md): five versions of the highlight, and why fewer layers won

## Problems fixed

- ["I hold ⌥ and nothing happens"](fix-accessibility-permission-lost.md): three different causes, ending in a stable self-signed certificate
- [Drag to reorder didn't drag](fix-drag-reorder-list.md): a tap gesture swallowed the mouse-down
- [Unreadable ring text in light mode](fix-ring-text-light-mode.md): a dark ring with system-colored text
- ["Take from Dock" missed Chrome](fix-dock-import-missing-apps.md): a silent cut-off at 8 of 28 apps
- [An app you couldn't see](fix-no-icon-no-dock.md): no icon, and no Dock tile while Settings was open
- [Adding a setting would have wiped the user's ring](fix-config-migration-wipe.md): synthesized `Decodable` ignores defaults
- [The self-test that could never fail](fix-selftest-assert-stripped.md): `assert` disappears in release builds
- [Space did nothing](fix-app-activation-macos14.md): background apps can't activate others on macOS 14+, so Halo uses Accessibility instead

## Still unverified

Verified later with synthesized key events: the ring appears on hold, Space returns to the previous app, ⌥+1 opens slot 1, and the permission survives rebuilds.

Still open:

- The window list against real windows
- Picking an app by mouse direction, driven by a script
- Dropping apps from Finder onto the ring
