# AGENTS.md

Facts for coding agents installing, updating or changing Halo. Humans: see [README.md](README.md) (TL;DR) or [GUIDE.md](GUIDE.md) (full).

## Install / update / run

```yaml
repo: https://github.com/Rheinmir/halo
install_dir: ~/halo            # if it exists: git pull, then rebuild
requires: macOS 13+, Swift from the Command Line Tools (no Xcode)
build: ./build.sh              # success ends with "selftest OK" and "OK: …/Halo.app"
app: ~/halo/Halo.app
bundle_id: local.halo.ring
quit: osascript -e 'tell application id "local.halo.ring" to quit'   # before opening a new build; only one instance runs
open: open ~/halo/Halo.app
permission: Accessibility — the user must switch it on; it persists across rebuilds (stable "Halo Local Signing" cert)
open_permission_pane: open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
config: ~/Library/Application Support/Halo/config.json   # apps, trigger, delay, position, windows, tick, language
```

Rules: no `sudo`; don't install anything else; on build errors, report them instead of editing code. The user has to click the keychain "Always Allow" dialog and the Accessibility switch; an agent can't.

## Changing the code

- Build and test: `swift build -c release && .build/release/Halo --selftest`. Geometry changes need self-test cases in `Geometry.selftest()`.
- Every UI string goes through `tr("English", "Tiếng Việt")` (`Sources/Halo/L10n.swift`). English is the default.
- Screenshots in `docs/` (English) and `docs/vi/` (Vietnamese) come from the app itself:
  `--preview out.png [slot] [row "title" "~minimized" …]`, `--preview-settings out.png apps|general|about [light]`, plus `--lang en|vi`.
- Keep `README.md` / `README.vi.md` (TL;DR) and `GUIDE.md` / `GUIDE.vi.md` (full) in sync when behavior changes.
- Write a devlog post in `docs/devlog/` for each feature or problem, and mirror it as a closed issue with the `devlog` label.
- Code map: `Hotkey.swift` (event tap), `Geometry.swift` (ring and window-list layout), `Ring.swift` (ring UI, panel), `Windows.swift` (Accessibility windows, bringing apps forward), `Settings.swift`, `Apps.swift` (config, Dock), `main.swift` (wiring, CLI flags).
