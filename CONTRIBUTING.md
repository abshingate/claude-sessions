# Contributing

Bug reports welcome, especially from setups unlike the one this was built on — different
terminals, `bash` instead of `zsh`, a Mac without Homebrew.

## Before you send a fix

**Test against the real thing, not the config.** Most of the bugs found while building this
came from a check that read a *display artefact* rather than the state itself:

- Tab titles were used to find running sessions. When tabs were renamed, it reported
  **1 open session while 14 were running** — a restore would have brought back one of fourteen.
  Fixed by reading the process table.
- A "session started" check passed while the session was actually stuck on a folder trust
  prompt, forever. It looked identical to a working one.
- `tmux list-panes` reports `bash`, not `claude`, because claude is a *child* of the pane's
  shell. Taken at face value this reads as "claude died".

So: verify with `ps`, `tmux ls`, and by opening the thing — not by reading a title or a config
file.

## Style

- zsh for the shell tools, Python 3 (stdlib only) where shell gets awkward.
- No external dependencies beyond tmux, iTerm2 and Claude Code.
- Comment *why*, not *what* — especially where a fix looks arbitrary. Several comments in here
  name the exact failure that motivated them; keep that habit.
