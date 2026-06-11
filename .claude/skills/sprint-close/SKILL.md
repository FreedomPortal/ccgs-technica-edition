---
name: sprint-close
description: Orchestrates full sprint close-out sequence with confirmation gates between each step.
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Write, Task, AskUserQuestion
model: haiku
---

# /sprint-close

Runs the sprint close-out sequence in order. Pauses for user confirmation at each gate.

**Sequence:** `/milestone-review → /smoke-check sprint → /team-qa sprint → /retrospective → /gate-check`

Does NOT include `/sprint-plan new` — run that separately in a fresh session.

---

## Phase 0: Read Sprint Number

Read `production/sprint-status.yaml`. Extract `sprint: N`.

If missing: "Cannot determine sprint number. Verify `production/sprint-status.yaml` exists." Stop.

---

## Phase 1–5: Step Execution Loop

Run each step below in order using the **Gate-and-Record cycle** (see below).
Step 5 (gate-check) uses a special override — see **Step 5 Override** section.

| # | Skill | Invoke as |
|---|-------|-----------|
| 1 | Milestone Review | `Skill("milestone-review")` |
| 2 | Smoke Check | `Skill("smoke-check", "sprint")` |
| 3 | Team QA | `Skill("team-qa", "sprint")` |
| 4 | Retrospective | `Skill("retrospective")` |
| 5 | Gate Check | see Step 5 Override |

### Gate-and-Record Cycle (steps 1–4)

**Before running**: Display progress header:
```
── Sprint #N Close-Out ──────────────────────
Step X / 5: /[skill-name]
```
Ask user to confirm: "[Y] Run / [N] Abort"
- If N: "Close-out paused. Run `/sprint-close` again to resume or continue steps manually." Stop.

**Run the skill.**

**If BLOCKED detected in output:**
> Surface the blocker message verbatim. Ask:
> "Blocker detected. Allow Sonnet-level analysis to help resolve it? [Y/N]"
> - Y → spawn `Agent` with `model: "sonnet"`, pass full blocker context + sprint N.
>   Present findings. Ask: "Continue close-out or pause to resolve first?"
> - N → ask: "Continue anyway (note blocker in report) or abort?"

**After step completes:**
Display 1–3 line summary of the result.

Ask: "May I record this summary and continue to `/[next-skill]`? [Y/N]"
- Y → append step result to draft at `production/session-state/drafts/sprint-close-N-YYYYMMDD.md`. Proceed.
- N → "Paused. Draft saved. Resume manually." Stop.

---

### Step 5 Override: Gate Check

Display progress header:
```
── Sprint #N Close-Out ──────────────────────
Step 5 / 5: /gate-check
```

Before running, glob for existing report: `production/gate-checks/gate-check-*.md`

**If found — read the most recent file:**

Extract and display:
- Report filename + date
- Overall verdict line (grep `Verdict:` or `## Verdict` or `PASS`/`FAIL` near top)
- Failing items: grep lines matching `FAIL`, `BLOCKED`, `❌`, `[ ]`, or `- ✗`
- Concern items: grep lines matching `CONCERN`, `WARNING`, `⚠`, `[~]`, or `- ⚠`
— display each group as a short bulleted list (cap at 10 lines per group; note "…and N more" if truncated)

```
── Sprint #N Close-Out ──────────────────────
Step 5 / 5: /gate-check

Existing report: [filename]
  Verdict : [PASS / FAIL / CONCERNS]
  Date    : [YYYY-MM-DD]

  Still failing:
    - [item 1]
    ...
  (or "None" if no matches)

  Concerns:
    - [item 1]
    ...
  (or "None" if no matches)
```

Ask:
> "How would you like to proceed?"
> - [A] Skip — use existing report
> - [B] Run `/gate-check` fresh (replaces existing)
> - [C] Abort close-out

- A → record existing report path in draft. Proceed to Phase 6.
- B → run Gate-and-Record cycle for gate-check (normal flow). Proceed to Phase 6.
- C → stop.

**If no existing report found:**
Run Gate-and-Record cycle for gate-check normally.

---

## Phase 6: Write Full Report

Ask: "May I write the close-out report to
`production/sprint-close/sprint-close-N-YYYYMMDD.md`? [Y/N]"

- Y → write report (see format below).
- N → "Report not written. Draft at `production/session-state/drafts/sprint-close-N-YYYYMMDD.md`."

### Report Format

```markdown
# Sprint #N Close-Out Report
Date: YYYY-MM-DD

## Milestone Review
[1–3 lines]

## Smoke Check
[1–3 lines: verdict, test count]

## Team QA
[1–3 lines: verdict, conditions if any]

## Retrospective
[1–3 lines: file path, key findings]

## Gate Check
[1–3 lines: verdict, skipped/run, blockers if any]

## Status
Sprint #N: CLOSED
```

---

## Phase 7: Close Declaration

**Backlog sync**: If `production/backlog.yaml` exists, silently sync all sprint stories:
- Re-read `production/sprint-status.yaml` final state
- For each story with `status: done` → update backlog entry: `status: done`, `completed_date: [completed field value]`
- For each story with `status: backlog` (not completed this sprint) → update backlog entry: `status: carried-over`
No confirmation needed — this is automatic on sprint close.

Display:

```
╔══════════════════════════════════════╗
║  Sprint #N: CLOSED                   ║
╚══════════════════════════════════════╝

Next:
  1. /checkpoint      — flush session knowledge to memory
  2. /sprint-plan new — plan Sprint N+1 (fresh session recommended)
```

Verdict: COMPLETE
