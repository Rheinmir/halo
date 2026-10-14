# Drag to reorder didn't drag

*Written 2026-10-14 · Structure: problem*

## How it showed up

The Apps tab lists the apps on the ring. We switched it to a SwiftUI `List` with `.onMove`, which should give native drag-to-reorder on macOS. The user tried it: "ủa không kéo được" — it doesn't drag.

## Why it happened

Each row had an `.onTapGesture` to select it. On macOS, that gesture claims the mouse-down, so the `List` never got the chance to start a drag. This is the likely cause rather than a proven one: removing the gesture made dragging work, but we didn't test the gesture in isolation.

## Fix

Selection now goes through the list's own mechanism, `List(selection: $store.selection)` with `.tag(i)` on each row, and the tap gesture is gone. See [`Settings.swift`](../../Sources/Halo/Settings.swift). We also added a ≡ grip to each row so it's obvious it can be dragged.

## Verification

We didn't want to rely on "it should work now," so we simulated a real drag. A script posted `CGEvent` mouse-down, a series of mouse-dragged events, and mouse-up on row 1, ending below row 3. Then it read `config.json`:

```
before: Launchpad, Vivaldi, Orca, Maps
after:  Vivaldi, Orca, Launchpad, Maps
```

The user's original order was restored afterwards.

## Remaining limits

- The drag test uses fixed window-layout offsets. It will need updating if the Settings layout changes.
