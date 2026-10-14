# Choosing the exact window from the ring

*Written 2026-10-14 · Structure: feature*

## What the user needed

The user asked: if an app has several windows, open another level to pick the window. Switching to the browser isn't enough when you want *the* window with a particular project.

## What the feature had to do

- Appear only when the app under the pointer has two or more windows.
- Let you pick a window without letting go of the key.
- Bring exactly that window forward, and restore it if it's minimized.
- Avoid asking for any permission beyond Accessibility.

## Why this design

**Accessibility API, not the window server list.** `CGWindowListCopyWindowInfo` only returns window titles if the app has Screen Recording permission. Halo already has Accessibility, and `AXUIElement` gives titles, minimized state and a raise action. [`Windows.swift`](../../Sources/Halo/Windows.swift) keeps only `AXStandardWindow` subroles, so panels and sheets stay out of the list.

**A list beside the ring, not a second ring.** Window titles are long. A vertical list next to the ring keeps them readable. It opens on the side the app's slot is on (left half → left, otherwise right) and is vertically centered on that slot.

**"Leave the ring to enter the list."** Inside the ring you pick apps. Once the pointer passes the ring's edge on the list's side, the app stays locked and the nearest row is selected. Move back in, and you're picking apps again. This rule lives in `Geometry.rowIndex` and is covered by the self-test.

## How it works

1. Pointer enters a running app's slot → Halo reads that app's windows.
2. Two or more → the center says "*N* cửa sổ ›" and the list appears.
3. Pointer goes out past the edge toward the list → the nearest row highlights.
4. Release → un-minimize if needed, set it as main, raise it, activate the app.

The keyboard works too: ↓ enters the list, ↑/↓ move.

<p align="center"><img src="../ring-windows.png" width="640" alt="Window list beside the ring"></p>

## Real results

- The self-test covers the selection rules (7 window-list checks).
- The screenshot above is a render with **fake window titles** via `--preview out.png 1 1 "A" "~B" …`.

## Gaps

- Not yet tried against real windows, since the permission wasn't granted during development.
- Only windows on the current Space are listed. That's a limitation of the Accessibility API.
