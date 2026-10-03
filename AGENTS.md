# Working on this repo

A learning system (skills + subagents) packaged for Claude Code, Codex and OpenCode. Ported from the pi config at github.com/amosblomqvist/learn. The first commit is the untouched upstream import, so `git diff <first-commit> -- skills agents` shows every porting change.

## Layout

- `skills/<name>/SKILL.md`: Agent Skills format, shared by all three tools as is. Keep them **harness-neutral**: name a move ("the structured question tool", "spawn the researcher subagent") and map it to each tool's real name in one place (see the top of `skills/teach/SKILL.md`). Don't scatter tool-specific names through the prose.
- `skills/visualize/scripts/*.sh`: the render/publish scripts the maker subagents call. Bash, no dependencies beyond mmdc/npx and rsvg-convert/magick. Keep the CLI stable: the agent prompts depend on it.
- `agents/<name>.md`: **source** for each subagent. `+++` TOML frontmatter (`name`, `description`, `[claude]`, `[opencode]`, `[codex]`), then the shared prompt body.
- `dist/`: **generated** by `scripts/build-agents.py`, committed because `install.sh` symlinks to it. Never edit by hand.
- `install.sh` / `uninstall.sh`: symlink installer. Never overwrites anything that isn't its own symlink.

## Rules

- After changing `agents/*.md`, run `python3 scripts/build-agents.py` and commit `dist/` with it. `--check` verifies it is fresh.
- Per-tool frontmatter keys pass straight through: `[claude]` → Claude Code agent YAML (`tools`, `model`), `[opencode]` → OpenCode agent YAML (`mode: subagent` is added; use `permission`, not the deprecated `tools`), `[codex]` → Codex agent TOML (any `config.toml` key: `model_reasoning_effort`, `sandbox_mode`, `web_search`, …).
- Codex/OpenCode models are deliberately left unset, so they use the user's default.
- Keep the teaching text faithful to upstream. Port changes are for tool mechanics, not pedagogy.

## Checks

```bash
python3 scripts/build-agents.py --check
bash -n install.sh uninstall.sh skills/visualize/scripts/*.sh
./install.sh --dry-run
d=$(mktemp -d); printf 'graph TD\n A-->B\n' > $d/a.mmd && skills/visualize/scripts/render_mermaid.sh $d/a.mmd $d/a.png
```
