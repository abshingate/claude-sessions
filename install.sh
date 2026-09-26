#!/bin/zsh
# claude-sessions installer
set -e

PREFIX="${PREFIX:-$HOME/.local}"
SRC="${0:A:h}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/claude-sessions"

print "claude-sessions — installing to $PREFIX/bin"

# --- prerequisites, checked rather than assumed ---
missing=()
command -v tmux    >/dev/null 2>&1 || missing+=("tmux (brew install tmux)")
command -v claude  >/dev/null 2>&1 || missing+=("claude (Claude Code CLI)")
[[ "$(uname)" == "Darwin" ]] || missing+=("macOS (this uses AppleScript)")
if (( ${#missing} )); then
  print -u2 "\nMissing prerequisites:"
  for m in $missing; do print -u2 "  • $m"; done
  print -u2 "\nInstall these first, then re-run."
  exit 1
fi
[[ -d /Applications/iTerm.app ]] || \
  print "  note: iTerm2 not found. cc/cct/ccw need it (brew install --cask iterm2)"

mkdir -p "$PREFIX/bin" "$PREFIX/share/claude-sessions" "$CONFIG"
install -m 755 "$SRC"/bin/* "$PREFIX/bin/"
install -m 644 "$SRC"/share/* "$PREFIX/share/claude-sessions/"

if [[ ! -f "$CONFIG/projects.conf" ]]; then
  install -m 644 "$SRC/share/projects.conf.example" "$CONFIG/projects.conf"
  print "  created $CONFIG/projects.conf — edit it with your projects"
else
  print "  kept existing $CONFIG/projects.conf"
fi

print "\nInstalled: $(ls "$SRC"/bin | tr '\n' ' ')"
case ":$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *) print "\n⚠ $PREFIX/bin is not on your PATH. Add to ~/.zshrc:\n    export PATH=\"$PREFIX/bin:\$PATH\"" ;;
esac
print "\nNext:"
print "  1. \$EDITOR $CONFIG/projects.conf"
print "  2. cct <shortcut>     start a session"
print "  3. cc                 bring everything back later"
print "\nOptional — default flags for every session (see README, read it first):"
print "  export CLAUDE_DEFAULT_FLAGS=\"--chrome\""
