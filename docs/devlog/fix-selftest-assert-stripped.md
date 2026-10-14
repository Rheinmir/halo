# The self-test that could never fail

*Written 2026-10-14 · Structure: problem*

## How it showed up

`build.sh` runs `Halo --selftest` after every build and prints `selftest OK`. The first versions printed it every time. Then, while adding a second preview mode, we noticed the self-test used `assert(...)`.

## Why it happened

`build.sh` builds with `swift build -c release`. In optimized builds, Swift removes `assert` entirely. The checks were never evaluated, so `selftest OK` meant only "the function returned".

## Fix

All checks in [`Geometry.swift`](../../Sources/Halo/Geometry.swift) now use `precondition`, which stays active in release builds and stops the process on failure.

## Verification

- After the change, the self-test still passes in the release binary that `build.sh` produces.
- The suite later grew from 8 to 15 checks when the window list was added: list side, the "still inside the ring" case, the wrong-side case, clamping to the first and last row, and "one window doesn't open a list".

## Remaining limits

- No check was written to prove a failing `precondition` actually stops the build. The behavior comes from the language, not from a test in this repo.
