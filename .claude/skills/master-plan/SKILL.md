---
name: master-plan
description: "Generate MASTER_PLAN.md — all epics, stories done/total per epic, current milestone and gate status. One command for the full picture across all sprints and milestones. Use when the user asks 'what's left to ship', 'show me the full plan', 'epic progress', or invokes /master-plan."
argument-hint: "[none]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write
model: sonnet
---

# Master Plan

Generates `production/MASTER_PLAN.md` — a persistent, regeneratable view of all
epics and their story completion across the entire project. Writes the file without
asking for approval (reversible, known path). Reports what was written.

---

## 1. Find Backlog

Look for `production/backlog.yaml` in the current working directory.

If not found: output "No backlog found. Run `/backlog` to create one." and stop.

Read the full file. It contains a `stories:` list where each entry has at minimum:
- `id` — story identifier
- `epic` — epic slug
- `name` — story name
- `status` — one of: `done`, `in-sprint`, `backlog`, `archived`
- `milestone_target` — milestone this story belongs to (e.g., `vertical-slice`, `demo`, `alpha`)
- `sprint` — sprint number (may be absent for unstarted stories)

---

## 2. Find Project Identity

Try to determine a human-readable project name from any of these (first match wins):
1. `design/gdd/` — look for a top-level GDD file and extract the title
2. `production/milestones/active.txt` — may imply project name from context
3. The current working directory name (last path segment, convert hyphens to spaces,
   title-case)

Use whatever is found as `[Project Name]` in the output. Never hardcode.

---

## 3. Read Active Milestone

Read `production/milestones/active.txt`. This contains one line: the current milestone
slug (e.g., `vertical-slice`).

If not found: milestone = "none configured".

Read `production/milestones/definitions/[milestone-slug].md` if it exists. Extract:
- **Goal** — the paragraph under "## Goal"
- **In Scope** — the bullet list under "## In Scope" (epic slugs or feature names)
- **Out of Scope** — the bullet list under "## Out of Scope"

---

## 4. Find Latest Gate Status

Glob `production/milestones/` for files matching `*-review-*.md` or `*gate-check*.md`.
Sort by modification time descending. Read the most recent one.

Extract:
- **Verdict** — look for the string after "**Status**" or "Verdict:" or a line
  containing one of: PASS, FAIL, CONDITIONAL GO, GO, NO-GO, BLOCKED
- **Date** — from the filename (e.g., `vertical-slice-review-sprint8-2026-06-29.md`
  → `2026-06-29`) or the `**Date:**` frontmatter field

If no review files exist: gate status = "no gate check on record".

---

## 5. Aggregate Stories by Epic

From the backlog stories list:

**Counting rules:**
- Exclude `archived` stories from both numerator and denominator
- Numerator (done): `status: done` only
- Denominator (total): all non-archived stories in the epic
- `in-sprint` counts toward denominator but NOT numerator

Build a map: `epic_slug → { done: N, total: T, in_sprint: M, in_scope: bool }`

Mark `in_scope: true` for any epic that appears in the active milestone's "In Scope"
list, or whose stories have `milestone_target == active_milestone`.

**Sanity check (internal — do not print):** Sum of all `done` values must equal the
total count of stories with `status: done` in the backlog. Sum of all `total` values
must equal total non-archived stories. If these don't reconcile, add a warning line
to the output: `⚠ Story count mismatch — recheck backlog.yaml for duplicate IDs`.

---

## 6. Compute Summary Totals

- **Total done** = sum of all epic `done` counts
- **Total stories** = sum of all epic `total` counts
- **Overall %** = (total done / total stories) × 100, rounded to 1 decimal
- **Milestone scope done** = sum of `done` for in-scope epics only
- **Milestone scope total** = sum of `total` for in-scope epics only
- **Milestone %** = milestone scope done / milestone scope total × 100

---

## 7. Find In-Sprint Stories

From the backlog, collect all stories where `status: in-sprint`. For each: record
`id`, `name`, `epic`. These are shown in the header section of the output.

---

## 8. Write MASTER_PLAN.md

Write `production/MASTER_PLAN.md`. Use this exact format:

```markdown
# Master Plan — [Project Name]
**Generated:** [YYYY-MM-DD]
**Milestone:** [milestone-slug] — [milestone status: in-progress / none configured]
**Gate:** [verdict] ([date])

---

## Milestone Goal
[goal paragraph from milestone definition, or "No milestone definition found."]

---

## Current Sprint
[If any in-sprint stories exist:]
| ID | Story | Epic |
|----|-------|------|
| S8-01 | Story Name | epic-slug |
[If none:] No stories currently in-sprint.

---

## Milestone Scope: [milestone-slug]
**Progress:** [milestone scope done]/[milestone scope total] stories complete ([milestone %]%)

| Epic | Done / Total | % | Status |
|------|-------------|---|--------|
[For each in-scope epic, sorted by % complete descending:]
| [epic-slug] | [done]/[total] | [%]% | [✅ Complete / 🔄 In Progress / ⏳ Not Started] |

[Status key: ✅ = 100%, 🔄 = >0% and <100%, ⏳ = 0%]

---

## Full Epic Registry
**Overall:** [total done]/[total stories] — [overall %]%

| Epic | Done / Total | % | Milestone Scope |
|------|-------------|---|-----------------|
[For ALL epics (including out-of-scope and future-milestone epics), sorted by milestone_target then % complete descending:]
| [epic-slug] | [done]/[total] | [%]% | [milestone_target values present in this epic, comma-separated] |
```

**Notes on format:**
- `milestone_target` column: if an epic has stories targeting multiple milestones,
  list them comma-separated (e.g., `vertical-slice, alpha`). Use the most common
  target if the list would be too long.
- Do not include `archived` stories in any count.
- The "Status" column uses emoji only: ✅ 🔄 ⏳
- All percentages are integer (no decimal) except the overall summary line.

---

## 9. Report

After writing, output to the user:

```
MASTER_PLAN.md written → production/MASTER_PLAN.md

[Project Name] — [milestone-slug] milestone
[milestone scope done]/[milestone scope total] milestone stories complete ([milestone %]%)
[total done]/[total stories] total across all epics ([overall %]%)
Gate: [verdict] ([date])
```

Do not output the full file contents — just the summary above. The file is on disk.

---

## Collaborative Protocol

This skill writes one file to a known path and does not ask for approval. The file
is regeneratable at any time by running `/master-plan` again. If the user wants to
view it immediately, suggest `cat production/MASTER_PLAN.md` or opening the file.
