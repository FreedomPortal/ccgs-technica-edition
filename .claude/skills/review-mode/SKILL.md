---
name: review-mode
description: "Configure the project-wide director review mode. Controls how often specialist director agents are spawned across the workflow. Three levels: full (every key step), lean (phase gates only), solo (no director reviews)."
argument-hint: "[full|lean|solo] — omit to show current and ask"
user-invocable: true
allowed-tools: Read, Write, AskUserQuestion
---

# Review Mode

Controls how frequently director specialist agents (Creative Director, Technical Director,
Producer, Audio Director) are spawned across the 40+ skills that respect this setting.

## Phase 1: Read Current Setting

Check `production/review-mode.txt`. If it exists, read current mode.
If missing, the effective default is `lean`.

## Phase 2: Handle Argument

**If an argument was passed** (`full`, `lean`, or `solo`):
- Validate it is one of the three valid values
- If invalid: "Valid values: `full`, `lean`, `solo`"
- If valid: skip Phase 3, write immediately in Phase 4

**If no argument**: proceed to Phase 3.

## Phase 3: Show Current and Ask

Display current mode and options:

| Mode | Behavior |
|------|----------|
| `full` | Director specialists review at each key workflow step. Best for teams, learning the workflow, or when you want thorough feedback on every decision. |
| `lean` | Directors only at phase gate transitions (`/gate-check`). Skips per-skill reviews. Balanced approach for solo devs and small teams. **(Default when not configured)** |
| `solo` | No director reviews at all. Maximum speed. Best for game jams, prototypes, or if reviews feel like overhead. |

Use `AskUserQuestion`:
- **Prompt**: "Current review mode: `[current]`. Change it?"
- **Options**:
  - `full — Directors at every key workflow step (teams / learning)`
  - `lean — Directors at phase gates only (recommended for solo/small teams)`
  - `solo — No director reviews (jams / prototypes / maximum speed)`
  - `Keep current ([current])`

## Phase 4: Write Setting

Write the chosen value (one word, no trailing newline) to `production/review-mode.txt`.

Create `production/` directory if it does not exist.

Confirm: "Review mode set to `[mode]`." followed by one sentence describing what
will now happen across the workflow.

Verdict: COMPLETE

Recommended next: continue with any workflow skill — the new review mode applies immediately.

## Mode Reference

**`full`**: Every skill that supports director review will spawn the relevant specialist
agents. Highest signal, highest token cost. Use when thoroughness matters more than speed.

**`lean`**: Per-skill director reviews are skipped. Directors still run at `/gate-check`
(phase gate transitions) — that is their primary purpose in this mode. Good balance
for experienced solo devs who don't need hand-holding on every step.

**`solo`**: All director spawns are skipped everywhere, including `/gate-check`. Gate
checks become artifact-existence checks only — no qualitative assessment. Use for
rapid iteration where you are your own director.
