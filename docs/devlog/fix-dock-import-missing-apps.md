# "Take from Dock" missed Chrome

*Written 2026-10-14 · Structure: problem*

## How it showed up

The user asked what "Lấy từ Dock" (take from Dock) actually takes, and why Google Chrome wasn't included.

## Why it happened

We checked rather than guessed:

- The Dock had **28** pinned apps, with Chrome at position 3, and the file existed.
- Halo's Dock parsing handled Chrome correctly (`Google%20Chrome.app` → `/Applications/Google Chrome.app`).
- The button replaced the whole ring with the **first 8** pinned apps.
- Halo's config only contained the snapshot from its first launch, in which Chrome didn't appear among the first 8. The likely explanation is that Chrome was pinned later. We don't have the Dock's history to confirm it.

So nothing was broken. The design was the problem: a silent, fixed cut-off at 8 out of 28, and a button that overwrote everything.

## Fix

The button became a **Từ Dock ▾** menu. See [`Settings.swift`](../../Sources/Halo/Settings.swift) and [`Apps.swift`](../../Sources/Halo/Apps.swift).

- It re-reads the Dock each time it opens, and lists every pinned app with its icon.
- Clicking an app adds it. Apps already on the ring show ✓ and are disabled. Everything is disabled when the ring is full.
- "Replace with first 10 Dock apps" stays at the bottom, for anyone who wants the old behavior.
- First launch still seeds the ring with the first 8 pinned apps.

## Verification

Seconds after the new build launched, Chrome appeared at the end of the user's config (written 14:19:06). Our own scripted menu click had failed with an AppleScript syntax error, so this was most likely the user using the new menu. We count it as real but indirect evidence.

## Remaining limits

- Apps in the Dock's "recent" section aren't listed, only pinned ones.
