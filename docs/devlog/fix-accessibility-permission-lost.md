# "I hold ⌥ and nothing happens": chasing a disappearing permission

*Written 2026-10-14 · Structure: problem*

## How it showed up

Several times, the user held ⌥ and no ring appeared. The symptom was the same each time, but the causes were different.

## Why it happened

**Round 1 — the app wasn't running.** `pgrep` found no Halo process, and the permission database had no entry for it. A crash report did exist, but its stack trace (`Index out of range`, `Ring.swift:36`) came from our own `--preview` run with slot `-1`, not from the user. It was a real bug in how the center label indexed the app list, so we fixed it with a bounds check. But it wasn't why the ring was missing.

**Round 2 — no permission dialog.** After launch, the user saw no prompt. The permission database showed Halo registered with `auth_value = 0`: listed, but switched off. The fix was simply to open the Accessibility pane directly.

**Round 3 — the permission kept resetting.** Each rebuild produced a new ad-hoc signature. macOS ties Accessibility to the code signature, so every build looked like a new app, and the old grant no longer applied. During development we ran `tccutil reset` after each build to re-register, which meant the user had to turn the permission on again, every time.

## Options considered

1. Keep ad-hoc signing and accept re-granting after each build — what we did at first. It annoyed the user repeatedly.
2. Sign with an Apple Developer certificate — not available here.
3. Sign every build with the **same self-signed certificate**, created once on this Mac.

## Fix

[`build.sh`](../../build.sh) now creates a "Halo Local Signing" code-signing certificate in the login keychain the first time it runs, with `codesign` allowed to use its key, and signs every build with it. The certificate is not added to the system trust settings.

The designated requirement changed from a per-build hash to:

```
identifier "local.halo.ring" and certificate leaf = H"0684bb5f…"
```

## Verification

- Two consecutive builds produced the identical designated requirement, and `codesign --verify` passes.
- A build from a fresh `git clone` used the same certificate.

## Remaining limits

- Confirmed later: the user granted the permission at 14:28, and it was still granted (`auth_value = 2`) after several rebuilds.
- Deleting the certificate makes the next build create a new one, and the permission has to be granted again.
- A copy of the app still won't run on another Mac. That needs Developer ID signing and notarization.
