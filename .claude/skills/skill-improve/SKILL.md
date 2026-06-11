---
name: skill-improve
description: "Improve a skill using a test-fix-retest loop. Single skill: test → fix → retest → keep or revert. Batch mode: from-report [path] reads a suite report and processes failing skills one-by-one with human gate between each."
argument-hint: "[skill-name] | from-report [report-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash
model: sonnet
---

# Skill Improve

Two modes:

- **Single skill**: `test → fix → retest → keep or revert` on one named skill.
- **From report**: reads a `/skill-test suite` report, processes all failing skills
  one-by-one with a human gate between each.

---

## Phase 1: Parse Argument

Read the first argument.

- `from-report [path]` → go to **Phase 0** (batch mode from suite report)
- `[skill-name]` → continue to Phase 2 (single-skill mode)
- Missing argument → output usage and stop:

```
Usage: /skill-improve [skill-name]
       /skill-improve from-report [report-path]
Example: /skill-improve tech-debt
Example: /skill-improve from-report "CCGS Skill Testing Framework/results/skill-test-suite-2026-06-11.md"
```

For single-skill mode: verify `.claude/skills/[name]/SKILL.md` exists. If not, stop with:
"Skill '[name]' not found."

---

## Phase 0: From-Report Mode — Batch Improvement

### Step 1 — Read Report

Read the suite report at the given path. If not found, stop:
"Report not found at [path]. Run `/skill-test suite` first to generate one."

### Step 2 — Build Queue

Parse all `<!-- SKILL: [name] | verdict: FAIL ... -->` and
`<!-- SKILL: [name] | verdict: WARN ... -->` blocks from the report.

Read `CCGS Skill Testing Framework/catalog.yaml` to get `priority:` for each skill.

Order the queue: FAIL before WARN within each tier; tiers ordered critical → high → medium → low.

Check for a `<!-- QUEUE-POSITION: [N] -->` marker in the report (written on a previous
stopped session). If found, resume from position N rather than starting at 1.

Display the queue:

```
=== Skill Improve: From Report ===
Report: [filename]
Date:   [date from report header]

Improvement queue:
  FAIL: [N] skills  |  WARN: [N] skills  |  Total: [N]
  [Resuming from position N]  ← only if resuming

  1. /gate-check       FAIL  (critical)  — 2 category failures: G2, G4
  2. /design-review    FAIL  (critical)  — 2 category failures: R2, R5
  3. /story-readiness  WARN  (critical)  — 1 static warning: Check 5
  ...

Proceed with #1 (/gate-check)? [y] | Jump to specific skill? Type name. | Stop? [n]
```

If user types a skill name, jump to that position in the queue.

### Step 3 — Process Queue (Human-Gated Loop)

For each skill in queue (starting at current position):

**3a. Announce skill:**
```
── Skill [N] of [total]: /[name] ──────────────────────────
Verdict from report: [FAIL/WARN]
Issues: [failures list from report block]
```

**3b. Run single-skill improvement loop** (Phases 2–7 of this skill):
- Run baseline test (Phase 2)
- Diagnose (Phase 3)
- Propose fix (Phase 4)
- Write and retest (Phase 5)
- Verdict: kept / reverted (Phase 6)

**3c. Update report entry:**
Read the report file. Find the `<!-- SKILL: [name] ... -->` block.
Replace its verdict tag with the outcome:
- Improved and kept → `verdict: FIXED`
- No improvement, reverted → `verdict: UNCHANGED`
- User declined fix at Phase 4 → `verdict: SKIPPED-BY-USER`

Write the updated report back.

**3d. Ask to continue:**
```
Result: [FIXED / UNCHANGED / SKIPPED-BY-USER]

Next: /[next-name] ([verdict] — [issues summary])
Continue? [continue] | Skip next | Stop
```

- `continue` (or Enter) → move to next skill
- `skip` → mark next skill `SKIPPED-BY-USER`, advance one more
- `stop` → write `<!-- QUEUE-POSITION: [N+1] -->` to report, exit

### Step 4 — Session Summary

After all skills processed or user stops:

```
=== Improvement Session Complete ===

  Fixed:           N  (score improved, changes kept)
  Unchanged:       N  (no improvement found, reverted)
  Skipped by user: N
  Remaining:       N  (use /skill-improve from-report [path] to resume)

Report updated: [path]

Recommended next:
  /skill-test suite  — regenerate a clean baseline after fixes
```

---

---

## Phase 2: Baseline Test

Run `/skill-test static [name]` and record the baseline score:
- Count of FAILs
- Count of WARNs
- Which specific checks failed (Check 1–7)

Display to the user:
```
Static baseline:   [N] failures, [M] warnings
Failing: Check 4 (no ask-before-write), Check 5 (no handoff)
```

If baseline is 0 FAILs and 0 WARNs, note it and proceed to Phase 2b.

### Phase 2b: Category Baseline

Look up the skill's `category:` field in `CCGS Skill Testing Framework/catalog.yaml`.

If no `category:` field is found, display:
"Category: not yet assigned — skipping category checks."
and skip to Phase 3.

If category is found, run `/skill-test category [name]` and record the category baseline:
- Count of FAILs
- Count of WARNs
- Which specific category rubric metrics failed

Display to the user:
```
Category baseline: [N] failures, [M] warnings  ([category] rubric)
```

If BOTH static and category baselines are 0 FAILs and 0 WARNs, stop:
"This skill already passes all static and category checks. No improvements needed."

---

## Phase 3: Diagnose

Read the full skill file at `.claude/skills/[name]/SKILL.md`.

For each failing or warning **static** check, identify the exact gap:

- **Check 1 fail** → which frontmatter field is missing
- **Check 2 fail** → how many phases found vs. minimum required
- **Check 3 fail** → no verdict keywords anywhere in the skill body
- **Check 4 fail** → Write or Edit in allowed-tools but no ask-before-write language
- **Check 5 warn** → no follow-up or next-step section at the end
- **Check 6 warn** → `context: fork` set but fewer than 5 phases found
- **Check 7 warn** → argument-hint is empty or doesn't match documented modes

For each failing or warning **category** check (if category was assigned in Phase 2b),
identify the exact gap in the skill's text. For example:
- If G2 fails (gate mode, full directors not spawned): skill body never references all 4
  PHASE-GATE director prompts
- If A2 fails (authoring, no per-section May-I-write): skill asks once at the end, not
  before each section write
- If T3 fails (team, BLOCKED not surfaced): skill doesn't halt dependent work on blocked agent

Show the full combined diagnosis to the user before proposing any changes.

---

## Phase 4: Propose Fix

Write a targeted fix for each failure and warning. Show the proposed changes
as clearly marked before/after blocks. Only change what is failing — do not
rewrite sections that are passing.

Ask: "May I write this improved version to `.claude/skills/[name]/SKILL.md`?"

If the user says no, stop here.

---

## Phase 5: Write and Retest

Record the current content of the skill file (for revert if needed).

Write the improved skill to `.claude/skills/[name]/SKILL.md`.

Re-run `/skill-test static [name]` and record the new static score.
If a category was assigned, also re-run `/skill-test category [name]` and record the new category score.

Display the comparison:
```
Static:   Before [N] failures, [M] warnings  →  After [N'] failures, [M'] warnings
Category: Before [N] failures, [M] warnings  →  After [N'] failures, [M'] warnings  (if applicable)
Combined change: improved / no change / worse
```

---

## Phase 6: Verdict

Count the combined failure total: static FAILs + category FAILs + static WARNs + category WARNs.

**If combined score improved (combined failure count is lower than baseline):**
Report: "Score improved. Changes kept."
Show a summary of what was fixed in each dimension.

**If combined score is the same or worse:**
Report: "Combined score did not improve."
Show what changed and why it may not have helped.
Ask: "May I revert `.claude/skills/[name]/SKILL.md` using git checkout?"
If yes: run `git checkout -- .claude/skills/[name]/SKILL.md`

---

## Phase 7: Next Steps

- Run `/skill-test static all` to find the next skill with failures.
- Run `/skill-improve [next-name]` to continue the loop on another skill.
- Run `/skill-test audit` to see overall coverage progress.
- Run `/skill-test suite` to generate a fresh suite report after multiple fixes.
- Run `/skill-improve from-report [path]` to work through all failures in a suite report.
