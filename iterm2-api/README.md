# iTerm2 Python API daemon

`claude_sessions.py` runs automatically when iTerm2 starts and does two things
AppleScript cannot:

- **Window title** shows the focused session's **real working directory**, plus how many
  sessions are open:
  `Exadatum  —  ~/Documents/Exadatum  ·  14 sessions`
- **Tab titles** stay short — just the project name — so the tab strip is scannable while the
  wide window bar carries the detail.

## Install

```bash
./install.sh          # from the repo root - installs this too
```

Or by hand:

```bash
pip3 install --user iterm2
mkdir -p ~/Library/Application\ Support/iTerm2/Scripts/AutoLaunch
cp claude_sessions.py ~/Library/Application\ Support/iTerm2/Scripts/AutoLaunch/
defaults write com.googlecode.iterm2 EnableAPIServer -bool true
```

Restart iTerm2. The first run asks permission for the script to use the API.

## Why the API and not AppleScript

Inside tmux, **iTerm2's PWD component reports the outer shell's cwd** (`/Users/you`), not the
pane's — so the one piece of information worth showing is the one iTerm2 cannot determine.
tmux knows it; the daemon asks tmux and sets the title directly.

Three simpler routes were tried first and all failed:

| Attempt | Why it failed |
|---|---|
| `tmux set-titles-string "#S — #{pane_current_path}"` | Fixed the window bar **and broke every tab** — `set-titles` drives both in iTerm2, so tabs became too wide to scan |
| OSC 2 escape written to the pane tty | Blocked by `set-titles off`, which is required to keep tab names short |
| `Custom Window Title` reading a `user.` variable | Rendered empty |

The API sets a window title **independently of the tab**, which is the missing capability.

## Adding features

Each feature is a small async function taking the connection; register it in `main()`. The
useful hooks:

| Monitor | Fires when |
|---|---|
| `iterm2.FocusMonitor` | the focused session changes |
| `iterm2.NewSessionMonitor` | a session is created |
| `iterm2.KeystrokeMonitor` | key bindings |
| `iterm2.PromptMonitor` | a shell prompt is drawn |

Ideas that fit here: colour a tab when its session needs attention, a status-bar component
showing session count, a keybinding that jumps to the next idle session, auto-naming new tabs
from their git branch.

## Notes

- The periodic pass (every 5s, two `tmux` calls) catches changes no monitor reports — `cd`
  inside a pane, or a session ending elsewhere.
- Every helper swallows its own errors: a daemon that crashes takes the titles with it, and a
  wrong title is better than none.
