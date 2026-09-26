# claude-sessions

Run a lot of [Claude Code](https://claude.com/claude-code) sessions at once without losing
track of them — or losing them.

Sessions run inside **tmux**, so closing the terminal or a crash doesn't kill them. Tabs are
named after their project instead of all reading `tmux`. One command brings the whole
workspace back.

```
$ ccs
 1  i api          Rate limiter for the public endpoints
 2  i web          Checkout flow redesign
 3  i infra        Terraform state migration
$ ccs 3            → jumps to that tab
```

macOS + iTerm2 + tmux. See [Requirements](#requirements).

---

## The problem

Open a dozen Claude Code sessions across projects and two things go wrong:

1. **Every tab looks identical.** You can't tell which is which without clicking through.
2. **Closing the terminal kills them all**, and you resume each one by hand from a list of
   UUIDs.

## Install

```bash
git clone <this repo> claude-sessions
cd claude-sessions && ./install.sh
$EDITOR ~/.config/claude-sessions/projects.conf
```

`projects.conf` maps a shortcut to a directory:

```
api    ~/code/api-service
web    ~/code/web-app
infra  ~/code/infrastructure
```

## Dock icon

```bash
./dock/make-dock-app.sh --dock
```

Builds **Claude Workspace.app** into `/Applications` and adds it to the Dock. Clicking it runs
`cc` — so getting your whole workspace back is one click, whether the terminal was closed or
the machine rebooted. It logs to `~/.claude/cc-dock.log`, so a launch that fails says why
instead of doing nothing.

Omit `--dock` to just build it and drag it yourself.

## Richer window titles (optional)

The tab shows the project; the window bar shows **where that session actually is**:

```
Exadatum  —  ~/Documents/Exadatum  ·  14 sessions
```

This needs iTerm2's Python API, because inside tmux iTerm2 cannot see a pane's real working
directory — it reports the outer shell's. `install.sh` sets it up if `pip3 install --user
iterm2` has been run. See [iterm2-api/](iterm2-api/).

## Commands

| Command | Does |
|---|---|
| **`cc`** | **Bring everything back.** Reattaches if sessions are alive, restores from the saved map if the machine rebooted. The one command to remember. |
| `cct api` | New session in a project, as a tab. `-w` window, `-s` split, `-r` resume newest, `-n` shell only |
| `ccs` | List every running session; `ccs 3` jumps to one |
| `ccw api web infra` | Open several projects as tabs in one window |
| `cc-reattach` | Put tabs back after the terminal closed (sessions kept running) |
| `cc-session-map` | Save/restore which sessions were open (`save`, `show`, `restore`) |
| `cc-label` | Rename tabs after their tmux session |
| `cc-trust` | Report project folders that would stall on Claude's trust prompt |

## What survives what

| Event | Sessions survive? | Recovery |
|---|---|---|
| Close the terminal | ✅ still running | `cc` |
| Terminal crashes | ✅ still running | `cc` |
| **Reboot** | ❌ processes die | `cc` (restores by `--resume`) |

**Nothing survives a reboot** — a restart kills every process, and no terminal or multiplexer
changes that. What `cc-session-map` does is record *which sessions were open and where*, so
recovery is one command instead of hunting through `--resume` lists. Transcripts are always
safe on disk; only the mapping is lost.

## Default flags

Set `CLAUDE_DEFAULT_FLAGS` to apply flags to every session this tool starts:

```bash
export CLAUDE_DEFAULT_FLAGS="--chrome --remote-control"
```

**It is empty by default, deliberately.** In particular
`--dangerously-skip-permissions` disables every permission prompt — every file write, every
shell command, no confirmation. That may be right for a sandbox or a machine you fully
control. It should be a decision you make knowingly, not one inherited from a README, so this
tool will not turn it on for you.

## Requirements

- **macOS.** Window and tab control is AppleScript; there is no Linux or Windows path.
- **iTerm2** for `cc`, `cct`, `ccw` (`brew install --cask iterm2`).
- **tmux** (`brew install tmux`) — this is what makes sessions survive.
- **Claude Code** on your `PATH`.

`install.sh` checks all of these and refuses rather than half-installing.

### Recommended tmux setting

```bash
echo 'set -g focus-events on' >> ~/.tmux.conf
```

Without it Claude Code can't tell when its pane gains or loses focus.

## How it works

Each session runs as `tmux new-session -A -s <project> claude`. tmux's server is a separate
long-lived process, so the terminal is only a viewer — quit it and the sessions keep running,
detached. `cc-reattach` reconnects them.

Tab names come from `cc-label`, which matches iTerm2 sessions to tmux clients **by TTY**. That
is the only reliable link; iTerm2 otherwise displays the job name, which is `tmux` for every
tab.

`cc-session-map` reads `~/.claude/projects/*/*.jsonl` for each session's `sessionId` and `cwd`,
so the mapping is **derived from disk** rather than only remembered. If the saved map is lost,
`cc-session-map discover` rebuilds it.

## Known limits

- macOS only.
- Sessions older than 14 days aren't carried in the map; resume those by hand.
- A new project folder starts untrusted — run `cc-trust` before relying on a bulk restore.
- `cc-inbox` (queue a session from another device) needs a launch agent; see `docs/`.

## Licence

MIT. See [LICENSE](LICENSE).
