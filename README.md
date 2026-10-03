# learn

An AI learning system for **Claude Code, Codex and OpenCode**: a teaching skill that maps what you know, plans a lesson as a dependency graph, and teaches it node by node with graded quizzes, verified facts and rendered diagrams.

This is a port of [amosblomqvist/learn](https://github.com/amosblomqvist/learn), the system from the video [How I Use AI to Learn Things](https://www.youtube.com/watch?v=kzcI5F4tGiU), originally built as a [pi](https://github.com/earendil-works/pi) configuration. The teaching philosophy and agent prompts are the original author's. This repo replaces the pi-only extensions with things every harness already has.

## What's in it

- `skills/teach/`: the philosophy and the process (probe → plan → teach), plus `references/quiz-protocol.md` for graded questions
- `skills/visualize/`: adds a correct, minimal diagram to a lesson, plus render scripts in `scripts/`
- `agents/`: one source per subagent (`researcher`, `mermaid-maker`, `svg-maker`), built into each harness's format in `dist/`

Skills follow the [Agent Skills](https://agentskills.io) format, so one copy serves all three tools. Subagent formats differ per tool, so `scripts/build-agents.py` generates them.

## Install

```bash
git clone <this repo> ~/Documents/repos/learn
cd ~/Documents/repos/learn
./install.sh --dry-run   # see what it would link
./install.sh             # link into every detected tool
./install.sh claude      # ...or only the tools you name
```

It symlinks globally, so `git pull` updates everything in place:

| | Skills | Subagents |
|---|---|---|
| Claude Code | `~/.claude/skills/{teach,visualize}` | `~/.claude/agents/*.md` |
| Codex | `~/.agents/skills/{teach,visualize}` | `~/.codex/agents/*.toml` |
| OpenCode | reuses the Claude/Codex links (or `~/.config/opencode/skills/` when it's the only tool) | `~/.config/opencode/agents/*.md` |

It never overwrites an existing file or someone else's symlink. It warns and skips. `./uninstall.sh` removes only the symlinks that point into this repo. Both respect `CLAUDE_CONFIG_DIR`, `CODEX_HOME` and `XDG_CONFIG_HOME`.

### Requirements

- For diagrams: Node.js (`npx` fetches mermaid-cli on first use; `npm i -g @mermaid-js/mermaid-cli` is faster) and `rsvg-convert` (`brew install librsvg`; ImageMagick works as a fallback). A local Chrome/Chromium is reused if present.
- To read lessons nicely: [Obsidian](https://obsidian.md) (or any markdown viewer with callouts, LaTeX and mermaid).

## Use

Open your harness in a folder you use for learning (it can be an Obsidian vault) and ask it to teach you something, or invoke the skill directly (`/teach` in Claude Code). It will:

1. propose a log file (`lessons/<topic>.md`) and mirror the lesson there as you go,
2. probe your level with quizzes and ask what you're after,
3. research the topic with the `researcher` subagent and present a plan with a dependency map,
4. after your go-ahead, teach node by node: motivate, establish, connect, quiz.

Diagrams land in `lessons/viz/` and are embedded in the log.

## Differences from the pi version

| pi | here |
|---|---|
| `quiz` extension (graded popup, auto-shuffle, built-in "I don't know" and note field) | The harness's own question tool + `quiz-protocol.md`. The agent grades in its next message, shuffles itself, and adds "I don't know" as an option. The free-text "Other" field is the note. |
| `ask-user-question` extension | Native: `AskUserQuestion` (Claude Code), `question` (OpenCode), `request_user_input` (Codex) |
| `md-log` extension (mirrors the session automatically) | The teach skill tells the agent to append to the log itself. It's the same format (callouts, the question before the answer, no tool noise), but it depends on the model following instructions. |
| `visual-tools` extension (`write_/edit_/render_*` tools) | `skills/visualize/scripts/{render_mermaid,render_svg,publish}.sh`, which makers run with their normal file and shell tools |
| `![[viz-….png\|500]]` wikilink | `![slug\|500](viz/viz-….png)`: Obsidian still sizes it, and any other markdown viewer renders it too |
| models in agent frontmatter | Claude Code: `sonnet`. Codex/OpenCode: your default model |

### Per-tool caveats

- **Claude Code**: makers use plain `Bash`, so expect permission prompts for the render scripts unless you allow them.
- **Codex**: `request_user_input` only exists in Plan mode, unless you enable `features.default_mode_request_user_input = true` in `~/.codex/config.toml`. Without it, quizzes fall back to plain-text A/B/C/D, which still works. The researcher agent sets `web_search = "live"`. The makers run in `workspace-write`, where `npx` can't download, so install mermaid-cli globally.
- **OpenCode**: the `question` tool is on in the TUI/app. The makers may only run the render scripts without asking (`permission.bash`).

## Development

Edit the sources, not `dist/`:

```bash
python3 scripts/build-agents.py          # regenerate dist/ after editing agents/*.md
python3 scripts/build-agents.py --check  # fails if dist/ is stale
```

See `AGENTS.md` for the details.

## Credits

Teaching skill, visualize skill and agent prompts: [Amos Blomqvist](https://github.com/amosblomqvist/learn). The teaching skill is written for one learner, so edit it to fit how you learn.
