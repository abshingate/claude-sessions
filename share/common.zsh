# common.zsh — shared configuration for the claude-sessions tools.
# Sourced by every command; keeps one definition of where things live.

: ${CS_CONFIG_DIR:="${XDG_CONFIG_HOME:-$HOME/.config}/claude-sessions"}
: ${CS_PROJECTS_FILE:="$CS_CONFIG_DIR/projects.conf"}
: ${CS_STATE_DIR:="$HOME/.claude"}

# Flags applied to every session this tool starts.
#
# NOTE: --dangerously-skip-permissions is deliberately NOT a default. It
# disables every permission prompt, so it has to be a choice the user makes
# knowingly, in their own config - not something inherited from a README.
: ${CLAUDE_DEFAULT_FLAGS:=""}

# Load <shortcut> -> <path> into the PROJ associative array.
cs_load_projects() {
  typeset -gA PROJ
  PROJ=()
  [[ -r "$CS_PROJECTS_FILE" ]] || return 0
  local key val
  while read -r key val; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    val="${val/#\~/$HOME}"
    val="${val//\$HOME/$HOME}"
    PROJ[$key]="$val"
  done < "$CS_PROJECTS_FILE"
}

# Resolve a shortcut or a path to an absolute directory.
cs_resolve() {
  local t="$1"
  cs_load_projects
  [[ -n "${PROJ[$t]:-}" ]] && { print -r -- "${PROJ[$t]}"; return }
  t="${t/#\~/$HOME}"
  [[ "$t" != /* ]] && t="$PWD/$t"
  print -r -- "$t"
}

cs_no_projects_hint() {
  print -u2 "No projects configured."
  print -u2 "  mkdir -p ${CS_CONFIG_DIR}"
  print -u2 "  cp <install>/share/projects.conf.example ${CS_PROJECTS_FILE}"
  print -u2 "  \$EDITOR ${CS_PROJECTS_FILE}"
}
