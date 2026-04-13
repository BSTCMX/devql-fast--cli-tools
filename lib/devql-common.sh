#!/usr/bin/env bash
# Shared devql launcher (bash / WSL / Linux / macOS).
# Contract: fd->fzf->editor (files), rg->fzf->editor (text).
# Runtime messages: English (v1.0). Read-only + open editor (no repo/system writes).

# Preflight: required binary must exist (one install hint per family: apt when available)
require_cmd() {
  local c="$1"
  if ! command -v "$c" >/dev/null 2>&1; then
    echo "Error: '${c}' not found in PATH." >&2
    if command -v apt-get >/dev/null 2>&1; then
      case "$c" in
        rg) echo "Install (apt): sudo apt install -y ripgrep" >&2 ;;
        fzf) echo "Install (apt): sudo apt install -y fzf" >&2 ;;
        bat) echo "Install (apt): sudo apt install -y bat" >&2 ;;
        fd) echo "Install (apt): sudo apt install -y fd-find (see INSTALACION.md for fd symlink)" >&2 ;;
        *) echo "See INSTALACION.md (WSL/Linux)." >&2 ;;
      esac
    else
      echo "See INSTALACION.md for your OS." >&2
    fi
    exit 1
  fi
}

# Open editor: code -g first if line jump requested, then EDITOR/VISUAL, then vi
devql_open_editor() {
  local file="$1"
  local line="${2:-}"

  if [[ -z "$file" ]]; then
    return 0
  fi

  if [[ -n "$line" ]] && command -v code >/dev/null 2>&1; then
    exec code -g "${file}:${line}"
  fi

  local ed="${EDITOR:-${VISUAL:-}}"

  if [[ -z "$ed" ]]; then
    ed="vi"
  fi

  if [[ -n "$line" ]] && [[ "$ed" =~ vim|nvim|gvim ]]; then
    exec "$ed" "+${line}" "$file"
  fi

  if [[ -n "$line" ]] && [[ "$ed" =~ ^code ]]; then
    exec code -g "${file}:${line}"
  fi

  if [[ -n "$line" ]]; then
    echo "Notice: opening file without reliable line jump for this editor." >&2
  fi

  exec "$ed" "$file"
}

# Preview fzf: bat or cat
devql_preview_cmd() {
  if command -v bat >/dev/null 2>&1; then
    echo "bat --style=numbers --color=always {} 2>/dev/null || cat {}"
  else
    echo "cat {}"
  fi
}

devql_cmd_files() {
  require_cmd fd
  require_cmd fzf

  local preview
  preview="$(devql_preview_cmd)"
  local raw
  raw="$(fd --type f --hidden --exclude .git 2>/dev/null || true)"
  if [[ -z "$raw" ]]; then
    echo "No files found in this tree." >&2
    exit 0
  fi

  local sel
  sel="$(echo "$raw" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-}" fzf \
    --preview "$preview" \
    --preview-window=right:60% || true)"
  if [[ -z "$sel" ]]; then
    exit 0
  fi
  devql_open_editor "$sel" ""
}

devql_cmd_text() {
  local pattern="${1:-}"
  if [[ -z "$pattern" ]]; then
    read -r -p "Search pattern (ripgrep): " pattern || exit 1
  fi
  if [[ -z "$pattern" ]]; then
    echo "Error: empty pattern." >&2
    exit 1
  fi

  require_cmd rg
  require_cmd fzf

  rg --line-number --no-heading --smart-case "$pattern" . >/dev/null 2>&1 || true
  local rc=$?
  if [[ $rc -eq 1 ]]; then
    echo "No matches." >&2
    exit 0
  fi
  if [[ $rc -ne 0 ]]; then
    echo "rg: search failed (exit $rc)." >&2
    exit "$rc"
  fi

  local sel
  sel="$(rg --line-number --no-heading --color=always --smart-case "$pattern" 2>/dev/null \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-}" fzf --ansi \
      --delimiter ':' \
      --nth '3..' \
      --preview 'f=$(echo {} | cut -d: -f1); bat --style=numbers --color=always "$f" 2>/dev/null || cat "$f"' \
      --preview-window=right:60% || true)"

  if [[ -z "$sel" ]]; then
    exit 0
  fi

  local fpath lineno
  fpath="$(echo "$sel" | cut -d: -f1)"
  lineno="$(echo "$sel" | cut -d: -f2)"

  devql_open_editor "$fpath" "$lineno"
}

devql_get_version() {
  local root="$1"
  local vf="${root}/lib/VERSION"
  if [[ -f "$vf" ]]; then
    tr -d ' \t\r\n' <"$vf"
  else
    echo "0.0.0"
  fi
}

devql_cmd_help() {
  local root="$1"
  local ver
  ver="$(devql_get_version "$root")"
  cat <<EOF
devql v${ver} — read-only search/navigation; opens your editor only when you pick a result.

USAGE:
  devql files           Pick a file by name (fd → fzf → editor)
  devql text [PATTERN]  Search contents (rg → fzf → editor; line jump when supported)
  devql help
  devql --version

Shortcuts (after setup / shims on PATH):
  qfiles                → devql files
  qtxt                  → devql text

Variables: EDITOR / VISUAL (default vi). Use code on PATH for line jumps.

More: GUIA-CLI.md
EOF
}
