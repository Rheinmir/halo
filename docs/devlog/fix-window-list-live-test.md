# What a real-mouse test found in the window list

*Written 2026-10-14 · Structure: problem*

## How it showed up

Until now, the window list had only been checked with rendered previews and fake window titles. We wrote a test that drives the real app with synthesized input: hold ⌥, move the pointer, release, then read the frontmost app and its focused window through Accessibility. The target was Microsoft Edge, sitting in slot 5 of 9 (lower right), with two real windows.

The first runs passed 2 of 5. A temporary debug log inside Halo (hover changes, rows, commits) showed why. There were three separate problems, plus one bug in the test itself.

## 1. The path to the list crossed another app

The list sat **beside** the ring, at the height of the slot. Edge's slot is diagonal, so the straight path from the icon to the list cut through the neighboring slot's wedge before it left the ring:

```
hover 4 (Edge) → windows 2 → hover 3 → windows 1   ← list disappears
```

**Fix:** the list is now placed **along the slot's direction**. Side slots get it just outside the ring on the ray from the center through the slot. Slots near the top or bottom get it above or below the ring. Moving further outward in the same direction always lands in the list. Row selection starts once the pointer is outside the ring and within one slot's angle of the app. See `listCenter` and `rowIndex` in [`Geometry.swift`](../../Sources/Halo/Geometry.swift).

The self-test now walks every slot of rings with 4, 6, 9 and 10 apps outward from the icon to the edge, and asserts it never leaves its slot and then reaches the list.

## 2. The chosen window didn't come forward

The log said Halo picked the right row, but the previously focused window stayed in front. Halo raised the window first and activated the app second. Activating the app brought its last main window back on top.

**Fix:** activate the app first, then set the window as main, raise it, and set it as the app's focused window. Activation is asynchronous, so the raise is repeated once after 0.15 s. See `raise` in [`Windows.swift`](../../Sources/Halo/Windows.swift).

## 3. The list header was unreadable on screen

The user spotted this one. The "Microsoft Edge · 2 windows" header was plain text floating above the list. It looked fine in renders, which have a dark background, but on the real, transparent ring it sat directly on whatever was behind, and was hard to read.

**Fix:** the header is now the top part of the list's glass card.

## The test's own bug

Halo orders the list by Accessibility's window order, which puts the frontmost window first. That order changes every time a window is raised. The test captured the titles once at the start, so it expected the wrong window. It now reads the order right before each pick, the same way Halo does.

## Verification

On the clean build, without the debug log, two runs in a row:

| Check | Result |
|---|---|
| Point at slot 1 (Zalo), release | Zalo frontmost ✅ |
| Point at slot 6 (Vivaldi), release | Vivaldi frontmost ✅ |
| Edge: pick row 2, row 1, row 2 | the focused window matches the row each time ✅ |
| Minimize a window, pick it | it's restored and focused ✅ |

A separate test dragged an app from a real Finder window onto the top slot of the Settings ring. It was inserted at position 1, twice in a row, and the user's config was restored afterwards.

One early failure turned out to be the physical mouse moving during the test: the log showed the pointer jumping between the scripted position and another one. Runs without interference passed.

## Remaining limits

- Row 1 in the tests is always the window that is already in front, so that check is weak. The row 2 checks are the meaningful ones.
- The bigger panel (864 × 904 pt) can extend past the edges of a small display when the ring opens there.
