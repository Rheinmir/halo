# Arranging apps directly on the ring

*Written 2026-10-14 · Structure: feature*

## What the user needed

Once list reordering worked, the user clarified what they actually meant: "kéo thẳng vô vòng luôn á" — drag right onto the ring. Then they added: drag the icons on the ring into different positions.

The ring is what you use every day. It's the natural place to decide where things go.

## What the feature had to do

- Drag an icon on the preview ring to another slot, and see the result before dropping.
- Drop an app from Finder onto a slot to insert it there.
- Click an icon to select it, synced with the list.
- Keep the real ring in sync immediately.

## Why this design

**Reuse the real ring view.** The editor draws the same `DiscView` used by the live ring, scaled to 0.72. What you arrange looks exactly like what you'll use.

**Preview by reordering, not by drawing a marker.** While dragging, the editor computes the order as if the drop happened already. The other icons slide into place with a spring, and the target slot is drawn faint as a placeholder. The dragged icon follows the pointer.

**Same geometry, inverse-scaled.** The drop slot comes from `Geometry.slotIndex`, with pointer coordinates divided by the editor's scale. A Finder drop computes slots for *n + 1* apps, because the ring will have one more slot after the insert.

## How it works

1. Mouse down on an icon, move more than 4 px → drag starts from that slot.
2. Each move → target slot = slot under the pointer, or the original slot if the pointer is in the dead zone.
3. Release → `store.move(from:to:)` saves the config and refreshes the live ring.
4. No movement → treated as a click, which selects the slot.
5. Finder drop → a `DropDelegate` highlights the slot during hover and inserts the app on drop. Disabled when the ring holds 10 apps.

## Real results

A simulated drag (posted `CGEvent`s) moved the top icon to slot 3:

```
before: Launchpad, Orca, Vivaldi, …
after:  Orca, Vivaldi, Launchpad, …
```

<p align="center"><img src="../settings-apps.png" width="560" alt="Apps tab with the editable ring"></p>

## Gaps

- **Dropping from Finder onto the ring hasn't been verified.** It needs a real drag from a Finder window, which the test scripts can't produce.
