# Halo

**Hold ⌥, flick toward an app, let go.** A ring launcher for macOS.

<p align="center"><img src="docs/ring-hover.png" width="560" alt="The Halo ring"></p>

<p align="center"><b>TL;DR</b> · <a href="GUIDE.md">Full guide</a> · <a href="docs/devlog/README.md">Devlog</a> · <a href="README.vi.md">Tiếng Việt</a></p>

## Install

Ask your coding agent (Claude Code, Codex, Cursor…):

```text
Install Halo from https://github.com/Rheinmir/halo by following its AGENTS.md.
```

Or by hand:

```bash
git clone https://github.com/Rheinmir/halo.git ~/halo && cd ~/halo && ./build.sh && open Halo.app
```

Then turn on **Halo** in System Settings → Privacy & Security → **Accessibility**.

## Use

| Do | Result |
|---|---|
| Hold ⌥ alone → move toward an app → release | Opens / switches to it |
| Move further out, past the ring's edge | Pick one of the app's windows |
| ⌥ + **Space** | Back to the previous app |
| ⌥ + **1–9** | Open that slot |
| Release in the center, or **Esc** | Cancel |
| Menu bar icon → **Settings…** | Drag apps onto the ring, change key, delay, language |

## Know before you use

macOS 13+ · Accessibility permission required · build from source (no download yet) · up to 10 apps · window list shows the current Space only · no network access · Apache 2.0

## Read more

- [Full guide](GUIDE.md): why Halo, every feature with screenshots, troubleshooting, development
- [Devlog](docs/devlog/README.md): the problems we hit and the decisions behind each feature
- [Issues](https://github.com/Rheinmir/halo/issues/25): docs and devlog index, open work

## For agents

Install, update and code facts are in [AGENTS.md](AGENTS.md), the file coding agents look for.
