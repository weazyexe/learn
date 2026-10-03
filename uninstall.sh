#!/usr/bin/env bash
# Remove the symlinks install.sh created. Same flags: [--dry-run] [claude] [codex] [opencode]
exec "$(dirname "${BASH_SOURCE[0]}")/install.sh" --uninstall "$@"
