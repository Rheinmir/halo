# Running the install prompt with a real agent

*Written 2026-10-14 · Structure: problem*

## How it showed up

The README's default install path is a prompt for a coding agent. Its commands had been run by hand, but no agent had followed the whole prompt ([#19](https://github.com/Rheinmir/halo/issues/19)). We gave the exact prompt from the README to a fresh, non-interactive Claude Code agent (`claude -p`, allowed tools: Bash and Read) twice:

1. **First install:** `~/halo` didn't exist.
2. **Update:** `~/halo` was on an older commit, the old build was running, and a new commit was on GitHub.

## Run 1: fresh install

The agent finished in 1 min 41 s. Checked independently afterwards:

- `~/halo` was cloned at the latest commit.
- `Halo.app` was built and signed with the same "Halo Local Signing" certificate, so the existing Accessibility grant still applied.
- Holding ⌥ opened the ring.

But **two Halo processes were running**: the development copy and the new `~/halo` copy. Both had an event tap, so both reacted to ⌥. A user updating with `git pull`, build, `open` hits the same thing: macOS launches the new bundle next to the old one.

## Why it happened

Nothing stopped a second instance. Each copy is a separate bundle on disk with the same identifier, and each one installs its own global event tap.

## Fix

- **Single instance:** at launch, Halo exits if another app with its bundle identifier is already running. See the end of [`main.swift`](../../Sources/Halo/main.swift).
- **The prompt quits the old build first:** step 4 now runs `osascript -e 'tell application id "local.halo.ring" to quit'` before opening the new build.

Checked before the second run:

- With one copy running, `open -n` on a second copy still left exactly one process.
- The quit command left zero processes.

## Run 2: update from the remote

We pushed the fix (`5670fe7`), started the old `~/halo` build (`d5db8d9`), and ran the prompt again. The agent finished in 58 s:

| Check | Result |
|---|---|
| `~/halo` commit | `d5db8d9` → `5670fe7` (pulled) |
| Running Halo processes | 1, started by the agent after it quit the old one |
| New binary includes the single-instance check | yes |

## Remaining limits

- Both runs used the same agent family and this Mac. Other agents (Codex, Cursor) haven't been tried.
- In both runs the agent asked the user to enable Accessibility, even though it was already on. The prompt now says to do so only if it isn't on yet.
- An agent can't click the keychain dialog or the Accessibility switch. Those steps always need the user.
