# Quiz protocol

`quiz` in the teach skill is a **move**, not a tool: a graded question with a known correct answer, followed by instant feedback. In pi it was a dedicated extension. Here it runs on whatever structured-question tool your harness has, and **you** do the grading.

## Which tool asks the question

| Harness | Tool | Notes |
|---|---|---|
| Claude Code | `AskUserQuestion` | 2–4 options per question. "Other" (free text) is added automatically. Supports `multiSelect`. |
| OpenCode | `question` | No hard option cap. "Type your own answer" is added automatically (`custom`, on by default). `multiple: true` for multi-select. |
| Codex | `request_user_input` | Only available in Plan mode unless the user enabled `features.default_mode_request_user_input`. Often absent. |
| None of the above | plain text | See "Fallback without a tool" below. |

If the tool call fails or the tool isn't in your toolset, use the fallback. Never stall.

## One quiz = two steps

### Step 1 — Ask (the tool call)

- **One question per call.** To probe nuance, ask several quick quizzes in a row and adapt each to the previous answer, not one giant question.
- **Options only.** Give the real, gradable options (at least two). With Claude Code's 4-option cap that usually means **3 real options + "I don't know"**. If you genuinely need 4 real options, leave out "I don't know" and say in the question text: *"Not sure? Pick Other and type 'idk'."*
- **"I don't know" is always available.** Add it as the **last** option, labelled exactly `I don't know`, unless the cap forces the Other-route above. Never add your own variants ("Not sure", "I'm not sure"…).
- **The free-text field is the note field.** Claude Code's "Other" and OpenCode's "Type your own answer" let the user attach a note or answer in their own words. Mention this in the question text only if it helps. Treat whatever they type there as their answer + note (see grading).
- **Never leak the answer.** The question text, header, option labels and option descriptions must not contain the correct answer, its justification, or any hint. Don't use the option `description`/`preview` fields to explain anything; leave them empty or make them perfectly parallel. Don't mark anything "(Recommended)".
- **Multi-select** (`multiSelect` / `multiple: true`) only when more than one option is correct. Graded as an exact-set match: correct only if every correct option and no incorrect one is selected.
- **Shuffle the options yourself.** The tool won't. Before writing the options, decide which slot the correct answer goes in, and vary it across quizzes: don't put it in the same slot twice in a row, and don't favour the first or the last slot. Exception: keep the order fixed when it carries meaning (ascending numbers, an "All/None of the above" that must stay last).

Before you send, **commit to the correct answer and the explanation in your head** (option label(s) + why). You will reveal them in step 2. Don't change them after seeing the answer.

### Step 2 — Grade (your very next message)

Right after the answer comes back, open your reply with a verdict block, then continue teaching:

```
> [!success] ✓ Correct
> Your answer: <label>
> Correct answer: <label>
>
> <explanation: why the correct answer is correct, and if they missed, what their pick reveals>
```

- Wrong answer: `> [!failure] ✗ Incorrect`, same body.
- "I don't know" (or "idk" typed into Other): `> [!question] I don't know`. Show only the correct answer and explanation, never a ✗. An honest "I don't know" is **a genuine gap to teach into, not a wrong answer**.
- Free text through Other: if it unambiguously matches one option, grade it as that option. If it's a note attached to a choice, grade the choice and use the note. If it's a fresh answer in their own words, judge it on substance and say so ("graded on substance: …").
- Note present: read it. It shows what they were thinking or unsure about, so let it steer the follow-up.
- Cancelled or skipped: `> [!warning] Quiz skipped`. Don't reveal the answer unless they ask.

**The explanation is mandatory.** Always say *why* the correct answer is correct. If they picked a distractor, name the misconception that distractor encodes. That is the diagnostic payoff.

## Writing the options

These come straight from the original quiz tool's guidelines. The construction procedure in the teach skill ("Writing quiz options") comes first; these back it up.

- **Distractors are diagnostic probes, not filler.** Each wrong option is a specific, believable mistake the learner might actually hold: a common misconception, or an adjacent/easily-confused concept. *Which* wrong answer they pick then tells you *which* nuance is off and what to teach next.
- **Guardrail:** every distractor must be unambiguously wrong on the intended reading. Tempting, but a real error, not a defensible alternative. No trick questions.
- **Anti-guessing hygiene:** the correct answer must not stand out by form (longest, most precise, most hedged, the only one in the right format). Keep options similar in length, specificity and phrasing.
- **No asymmetric formatting:** bold nothing, or bold the parallel term in every option.

## Fallback without a tool

Ask in plain text and **end your turn**:

```
> [!question] Quiz
> <question>
>
> A. <option>
> B. <option>
> C. <option>
> D. I don't know
>
> Reply with a letter (add a note after it if you want).
```

Grade in the next message exactly as in step 2. All the other rules (shuffle, no leaks, distractors) still apply.

## Logging

If a session log is active (see the teach skill, "Session log"), append the question **before** you get the answer (options in the order shown, never the correct answer), and append the verdict block after grading.
