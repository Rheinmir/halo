# Space did nothing: background apps can't activate others anymore

*Written 2026-10-14 · Structure: problem*

## How it showed up

The user asked for a shortcut: hold the key, the ring appears, press **Space**, and you're back on the previous app. We tracked the two most recently activated apps with `NSWorkspace.didActivateApplicationNotification`. On Space, Halo closed the ring and called `previousApp.activate()`.

A live test made the problem visible. It activated Finder, then Reminders, held ⌥ and pressed Space:

```
activation order: Reminders → Finder → Reminders
after Space, frontmost: Reminders      ← expected Finder
```

## Why it happened

Since macOS 14, app activation is "cooperative": a call to `NSRunningApplication.activate()` from an app that isn't frontmost is often ignored. Halo runs in the background by design, because the ring panel never takes focus. Our test script ran into the same rule: its own `activate()` call for Finder left a different app in front.

This is the explanation consistent with what we observed. We didn't find an official statement covering every case.

The same call was used when raising a window from the window list, so that path was likely affected too.

## Fix

`Windows.bringToFront(_:)` in [`Windows.swift`](../../Sources/Halo/Windows.swift):

1. Set `kAXFrontmostAttribute = true` on the app's Accessibility element. Halo already has that permission, and the call isn't subject to the activation rule.
2. If that fails, fall back to `NSWorkspace.openApplication` with `activates = true`.

Space, picking a running app on the ring, and raising a window all go through it now.

## Verification

Live, with synthesized key events:

| Test | Before | After |
|---|---|---|
| Finder → Reminders, hold ⌥, Space | stays on Reminders | **Finder** |
| Hold ⌥, press 1 (slot 1 = Zalo) | — | **Zalo** comes to front |
| Hold ⌥ for 0.6 s | — | ring panel is on screen |
| Release ⌥ in the center | — | ring closes, nothing opens |

The Accessibility permission stayed granted across these rebuilds (`auth_value = 2`), which confirms the stable signing from [the permission devlog](fix-accessibility-permission-lost.md).

## Remaining limits

- Raising a specific window from the list still hasn't been tested against real windows.
- "Previous app" only knows about activations that happened while Halo was running. Right after launch, Space does nothing until you've switched apps once.
