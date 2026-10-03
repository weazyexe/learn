#!/usr/bin/env bash
# Install the learn skills and subagents globally for Claude Code, Codex and OpenCode
# by symlinking them from this repo. Only tools that are present get linked.
#
# Usage: ./install.sh [--dry-run] [--uninstall] [claude] [codex] [opencode]
#   no tool names     -> every detected tool
#   --dry-run         -> print what would change, touch nothing
#   --uninstall       -> remove only the symlinks that point into this repo
#
# Existing files or foreign symlinks at a target path are never overwritten.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(teach visualize)

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
OPENCODE_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
AGENTS_SKILLS="$HOME/.agents/skills"

dry=0
mode=install
want=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry=1 ;;
    --uninstall) mode=uninstall ;;
    claude|codex|opencode) want+=("$arg") ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done

detected() {
  case "$1" in
    claude) command -v claude >/dev/null 2>&1 || [ -d "$CLAUDE_HOME" ] ;;
    codex) command -v codex >/dev/null 2>&1 || [ -d "$CODEX_HOME" ] ;;
    opencode) command -v opencode >/dev/null 2>&1 || [ -d "$OPENCODE_HOME" ] ;;
  esac
}

tools=()
if [ ${#want[@]} -gt 0 ]; then
  tools=("${want[@]}")
else
  for t in claude codex opencode; do
    if detected "$t"; then tools+=("$t"); fi
  done
fi
if [ ${#tools[@]} -eq 0 ]; then
  echo "No Claude Code, Codex or OpenCode found. Name a tool explicitly, e.g. ./install.sh claude" >&2
  exit 1
fi
has() { local t; for t in "${tools[@]}"; do [ "$t" = "$1" ] && return 0; done; return 1; }

warnings=0
say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; warnings=$((warnings + 1)); }
tilde() { printf '%s' "${1/#$HOME/~}"; }

link() { # link <src> <dst>
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "  ok      $(tilde "$dst")"
  elif [ -e "$dst" ] || [ -L "$dst" ]; then
    warn "$(tilde "$dst") already exists and is not our symlink, left untouched"
  elif [ $dry -eq 1 ]; then
    say "  link    $(tilde "$dst") -> $(tilde "$src")"
  else
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    say "  linked  $(tilde "$dst") -> $(tilde "$src")"
  fi
}

unlink_ours() { # unlink_ours <src> <dst>
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    if [ $dry -eq 1 ]; then say "  remove  $(tilde "$dst")"; else rm "$dst"; say "  removed $(tilde "$dst")"; fi
  elif [ -e "$dst" ] || [ -L "$dst" ]; then
    say "  skip    $(tilde "$dst") (not ours)"
  fi
}

apply() { if [ "$mode" = install ]; then link "$@"; else unlink_ours "$@"; fi; }

skills_into() { # skills_into <dir>
  local s; for s in "${SKILLS[@]}"; do apply "$REPO/skills/$s" "$1/$s"; done
}

agents_into() { # agents_into <tool> <dir>
  local f
  for f in "$REPO/dist/$1/agents/"*; do
    [ -e "$f" ] || { warn "no built agents in dist/$1, run: python3 scripts/build-agents.py"; return; }
    apply "$f" "$2/$(basename "$f")"
  done
}

[ $dry -eq 1 ] && say "(dry run, nothing will change)"
say "Tools: ${tools[*]}"

if has claude; then
  say "Claude Code:"
  skills_into "$CLAUDE_HOME/skills"
  agents_into claude "$CLAUDE_HOME/agents"
fi

if has codex; then
  say "Codex:"
  skills_into "$AGENTS_SKILLS"
  agents_into codex "$CODEX_HOME/agents"
fi

if has opencode; then
  say "OpenCode:"
  # OpenCode also reads ~/.claude/skills and ~/.agents/skills. Only give it its own
  # copy when neither of those is being installed, so it doesn't load each skill twice.
  if has claude || has codex; then
    say "  skills  shared via $(has claude && tilde "$CLAUDE_HOME/skills" || tilde "$AGENTS_SKILLS")"
    [ "$mode" = uninstall ] && skills_into "$OPENCODE_HOME/skills"
  else
    skills_into "$OPENCODE_HOME/skills"
  fi
  agents_into opencode "$OPENCODE_HOME/agents"
fi

if [ "$mode" = install ]; then
  say "Dependencies (for the visualize skill):"
  if command -v mmdc >/dev/null 2>&1; then
    say "  ok      mmdc"
  elif command -v npx >/dev/null 2>&1; then
    say "  ok      npx (mermaid-cli is fetched on first render; 'npm i -g @mermaid-js/mermaid-cli' makes it faster and works inside Codex's sandbox)"
  else
    warn "no mmdc or npx: install Node.js, then 'npm i -g @mermaid-js/mermaid-cli'"
  fi
  if command -v rsvg-convert >/dev/null 2>&1; then
    say "  ok      rsvg-convert"
  elif command -v magick >/dev/null 2>&1; then
    say "  ok      magick (rsvg-convert renders fonts better: brew install librsvg)"
  else
    warn "no rsvg-convert or magick: brew install librsvg"
  fi
fi

[ $warnings -gt 0 ] && say "Done with $warnings warning(s)." || say "Done."
