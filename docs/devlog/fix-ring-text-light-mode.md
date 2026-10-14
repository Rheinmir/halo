# Unreadable ring text in light mode

*Written 2026-10-14 · Structure: problem*

## How it showed up

While producing README screenshots in both appearances, the light-mode Settings screenshot showed the app name in the middle of the preview ring as dark text on a dark disc, barely visible.

## Why it happened

The ring is always dark glass, like a macOS HUD. But its text used `.primary`, which follows the system appearance and turns black in light mode. The live ring had the same problem: anyone using light mode would get dark text on the dark ring.

## Fix

In [`Ring.swift`](../../Sources/Halo/Ring.swift):

- The disc and the window list force `.environment(\.colorScheme, .dark)`.
- The live glass (`NSVisualEffectView`) gets `appearance = .vibrantDark`.

The Settings window itself still follows the system appearance.

## Verification

We re-rendered the light-mode Apps tab. The center text is now white on the dark ring, and every light screenshot in the README was regenerated.

## Remaining limits

- The live translucent ring in light mode has only been checked through renders, which use a solid background, not on screen.
