# Halo devlog

Notes on problems we hit and features we built, one topic per post. Each post says what we verified and what we didn't.

## Features

- [Building a ring launcher without Xcode](build-ring-launcher.md) ([#1](https://github.com/Rheinmir/halo/issues/1)): why not xtool, the event tap, the delay, the geometry
- [Choosing the exact window from the ring](build-window-picker.md) ([#4](https://github.com/Rheinmir/halo/issues/4)): Accessibility windows, "leave the ring to enter the list"
- [Arranging apps directly on the ring](build-arrange-on-ring.md) ([#6](https://github.com/Rheinmir/halo/issues/6)): drag icons between slots, drop apps from Finder
- [Settings that looked adjustable but weren't](build-trigger-key-and-delay.md) ([#10](https://github.com/Rheinmir/halo/issues/10)): choosable trigger key and delay
- [English and Vietnamese interface](build-bilingual-interface.md) ([#14](https://github.com/Rheinmir/halo/issues/14)): `tr()` strings, English by default, screenshots in both languages
- [One signal for "this slot is selected"](design-single-selection-signal.md) ([#7](https://github.com/Rheinmir/halo/issues/7)): five versions of the highlight, and why fewer layers won

## Problems fixed

- ["I hold ⌥ and nothing happens"](fix-accessibility-permission-lost.md) ([#3](https://github.com/Rheinmir/halo/issues/3)): three different causes, ending in a stable self-signed certificate
- [Drag to reorder didn't drag](fix-drag-reorder-list.md) ([#5](https://github.com/Rheinmir/halo/issues/5)): a tap gesture swallowed the mouse-down
- [Unreadable ring text in light mode](fix-ring-text-light-mode.md) ([#8](https://github.com/Rheinmir/halo/issues/8)): a dark ring with system-colored text
- ["Take from Dock" missed Chrome](fix-dock-import-missing-apps.md) ([#9](https://github.com/Rheinmir/halo/issues/9)): a silent cut-off at 8 of 28 apps
- [An app you couldn't see](fix-no-icon-no-dock.md) ([#11](https://github.com/Rheinmir/halo/issues/11)): no icon, and no Dock tile while Settings was open
- [Adding a setting would have wiped the user's ring](fix-config-migration-wipe.md) ([#12](https://github.com/Rheinmir/halo/issues/12)): synthesized `Decodable` ignores defaults
- [The self-test that could never fail](fix-selftest-assert-stripped.md) ([#2](https://github.com/Rheinmir/halo/issues/2)): `assert` disappears in release builds
- [What a real-mouse test found in the window list](fix-window-list-live-test.md): the path to the list crossed another app, raise order, unreadable header
- [Space did nothing](fix-app-activation-macos14.md) ([#13](https://github.com/Rheinmir/halo/issues/13)): background apps can't activate others on macOS 14+, so Halo uses Accessibility instead

## Still unverified

Verified later with synthesized key events: the ring appears on hold, Space returns to the previous app, ⌥+1 opens slot 1, and the permission survives rebuilds.

Verified later with real input: the window list with real windows, dropping from Finder onto the ring, and picking by pointer direction (see [the live-test devlog](fix-window-list-live-test.md)). Still open: [#18](https://github.com/Rheinmir/halo/issues/18) (macOS 13/14). Every devlog post is also an issue; the [index issue](https://github.com/Rheinmir/halo/issues/25) lists them all.
