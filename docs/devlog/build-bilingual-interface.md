# English and Vietnamese interface

*Written 2026-10-14 · Structure: feature*

## What the user needed

Halo's interface was Vietnamese only, so the README's screenshots were too, even after the README itself moved to English. The user asked for both languages, with **English as the default**.

## What it had to do

- Show every label, hint, menu item and ring text in English or Vietnamese.
- Default to English, and let users switch to Vietnamese or follow the macOS language.
- Switch immediately, without restarting.
- Produce screenshots in either language for the two READMEs.

## Why this design

**Strings in code, not `.strings` files.** About 50 strings, two languages, and a plain SwiftPM build. [`L10n.swift`](../../Sources/Halo/L10n.swift) has a single helper, `tr("English", "Tiếng Việt")`. Moving to a String Catalog makes sense if a third language arrives.

**Language is a config value.** `language` is `en` (the default), `vi` or `auto`. `auto` picks Vietnamese only when the first preferred macOS language is Vietnamese. Old config files without the key fall back to English, using the tolerant decoding from [an earlier fix](fix-config-migration-wipe.md).

**Set the language before publishing the change.** `SettingsStore.update` sets `L10n.lang` before assigning the new config, so the redraw caused by that change already uses the new language.

## Real results

- Every preview command accepts `--lang en|vi`. `docs/` holds the English screenshots, `docs/vi/` the Vietnamese ones.
- Adding the language row made the General tab overflow again: the tab bar was clipped, and the delay hint was cut off with "…". The window grew to 640 pt and the hint got shorter.
- The first Vietnamese screenshot showed "English" in the language picker, because previews read the real config. Previews now apply `--lang` to the picker too, without writing to the config file.

## Gaps

- No automatic check that every visible string goes through `tr`. A scan of non-ASCII string literals found none left in the UI code.
