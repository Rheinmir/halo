# Adding a setting would have wiped the user's ring

*Written 2026-10-14 · Structure: problem*

## How it showed up

It didn't reach the user. It was caught while adding the `windows` setting. The existing config struct had default values for `position` and `tick`, and adding `windows` the same way looked harmless.

## Why it would have happened

Swift's synthesized `Decodable` **ignores property defaults**. A key missing from the JSON makes decoding throw. Halo's loader treats a decode failure as "no config yet", builds a default ring from the Dock, and **saves it**. Every existing user would have lost their arrangement on upgrade.

## Fix

[`Apps.swift`](../../Sources/Halo/Apps.swift) has a hand-written `init(from:)` using `decodeIfPresent`, with a default for every key. The same pattern later covered `trigger` and `delay`, the latter clamped to 0–0.5.

## Verification

The user's config, written before `windows` existed, kept its apps after upgrading. Their app list was still there in the next session, now with `windows` set to its default. No dedicated test was written.

## Remaining limits

- An unknown `trigger` value falls back to ⌥ silently instead of reporting the problem.
