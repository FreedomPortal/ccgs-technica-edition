---
name: autosave-mode
description: "Configure autosave/draft-first enforcement level for the project. Controls how strictly Claude must write work products to disk before asking for approval at expensive task completion points (reviews, sprint plans, gate checks). Three levels: off, remind, enforce."
argument-hint: "[off|remind|enforce] — omit to show current and ask"
user-invocable: true
allowed-tools: Read, Write, AskUserQuestion
---

# Autosave Mode

Controls how the draft-first protocol is enforced when Claude reaches an approval gate
after a long-running task (code review, sprint planning, gate check, etc.).

## Phase 1: Read Current Setting

Check `production/autosave-mode.txt`. If it exists, read current mode.
If missing, the effective default is `remind`.

## Phase 2: Handle Argument

**If an argument was passed** (`off`, `remind`, or `enforce`):
- Validate it is one of the three valid values
- If invalid: "Valid values: `off`, `remind`, `enforce`"
- If valid: skip Phase 3, write immediately in Phase 4

**If no argument**: proceed to Phase 3.

## Phase 3: Show Current and Ask

Display current mode and options:

| Mode | Behavior |
|------|----------|
| `off` | No protection. Claude proceeds to approval gates without writing drafts first. Best for reliable machines or when you want maximum iteration speed. |
| `remind` | Stderr reminder before approval gates. Claude sees it and should write draft first. Non-blocking — relies on compliance. **(Default when not configured)** |
| `enforce` | Hard block. Claude cannot call AskUserQuestion with approval language unless a file was written to `production/session-state/drafts/` within the last 3 minutes. |

Use `AskUserQuestion`:
- **Prompt**: "Current autosave mode: `[current]`. Change it?"
- **Options**:
  - `enforce — Hard block (unstable machine / high-stakes production work)`
  - `remind — Soft reminder (recommended for most users)`
  - `off — No protection (reliable machine, max speed)`
  - `Keep current ([current])`

## Phase 4: Write Setting

Write the chosen value (one word, no trailing newline) to `production/autosave-mode.txt`.

Create `production/` directory if it does not exist.

Confirm: "Autosave mode set to `[mode]`." followed by one sentence describing what
will now happen at approval gates.

Verdict: COMPLETE

Recommended next: run any long-running skill (`/code-review`, `/sprint-plan`, `/gate-check`) — the configured protection level now applies at each approval gate.

## Levels Reference

**`off`**: The `pre-approval-check.sh` hook exits immediately on all calls.
No reminders, no blocks. Use when machine never crashes and you iterate fast.

**`remind`**: Hook prints a reminder to stderr before approval-gate AskUserQuestion
calls. Claude sees the message and should write the draft before proceeding.
Non-blocking — if Claude ignores it, the call goes through anyway.

**`enforce`**: Hook checks `production/session-state/drafts/` for any file modified
within the last 3 minutes. If none found, exits with code 2 (blocks the call).
Claude must write a draft file to `production/session-state/drafts/` first, then
retry. Files written by programmer subagents also count (SubagentStop hook writes
their output to the same directory).
