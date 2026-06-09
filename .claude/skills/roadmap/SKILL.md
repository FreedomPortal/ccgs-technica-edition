---
name: roadmap
description: Create and maintain production/roadmap.md — epic-to-milestone mapping, velocity-based completion horizon, and remaining work estimate. Modes: init, update, view.
model: sonnet
---

# /roadmap

Generates `production/roadmap.md` — the human-readable project roadmap.

**Inputs:**
- `production/backlog.yaml` — epics, stories, estimates (required)
- `production/milestones/definitions/` — scope contracts (optional but recommended)
- `production/sprints/` — historical sprint files for velocity (optional)

**Output:** `production/roadmap.md`

---

## Mode: init

Interactive — reads project state, proposes epic-to-milestone mapping, asks for confirmation, writes roadmap.md and updates backlog.yaml `milestone_target` fields.

### Phase 1 — Prerequisites

Check for `production/backlog.yaml`. If missing:
> "backlog.yaml not found. Run `/backlog init` first."
Stop.

Read:
- `production/backlog.yaml` — all epics and story counts
- `production/milestones/definitions/` — any existing milestone definitions
- `production/milestones/active.txt` — active milestone (if set)
- `production/sprints/sprint-*.md` — for velocity calculation

### Phase 2 — Velocity Calculation

From sprint files, extract per-sprint story completion data:

For each sprint file, read:
- Number of stories marked done
- Total estimate_days for completed stories
- Sprint start/end dates (for duration)

Compute:
- **Stories per sprint** (rolling average, last N sprints — use all available, cap at 5)
- **Estimate-days per sprint** (same)
- **Predictability** — % of must-have stories completed vs planned (from sprint-status entries)

If fewer than 2 sprints exist: note "Insufficient sprint history — velocity estimate is low-confidence."

### Phase 3 — Epic Summary

From `production/backlog.yaml`, group stories by epic. For each epic compute:
- Total stories
- Done count
- Remaining count (not done)
- Total remaining estimate_days
- Current milestone_target (may be `""`)

### Phase 4 — Milestone Assignment

For each epic where `milestone_target == ""` (unassigned), propose a milestone based on:
1. Whether the epic's in-scope systems appear in any milestone definition file
2. Heuristic: core loop systems → `vertical-slice`; content systems → `production`; polish/QA systems → `polish`

Present proposed assignments:

```
Epic-to-Milestone Mapping (proposed)
─────────────────────────────────────
  economy           → vertical-slice    (in-scope per VS definition)
  arena-visuals     → vertical-slice    (core loop)
  reward-screen     → vertical-slice    (core loop)
  workshop-ui       → vertical-slice    (core loop)
  [epic]            → production        (content system — heuristic)
  [epic]            → [?]               (unclear — your input needed)

Accept this mapping? [Y] Accept all / [E] Edit assignments / [N] Cancel
```

For any epic marked `[?]`: use `AskUserQuestion` to ask which milestone it belongs to.

### Phase 5 — Completion Horizon

Using velocity from Phase 2 and remaining work per milestone from Phase 3+4:

```
Completion Horizon (at [N]-sprint rolling average of [X] stories/sprint)

  vertical-slice    [N] stories remaining    ~[X] sprints    est. [date range]
  production        [N] stories remaining    ~[X] sprints    est. [date range]
  [next milestone]  [N] stories remaining    ~[X] sprints    est. [date range]

Confidence: [low/medium/high]
  low    = < 3 sprints of history, or variance > 40%
  medium = 3–5 sprints of history, variance < 40%
  high   = 5+ sprints of history, variance < 20%
```

Date range: center on velocity average ± 1 standard deviation sprint.

### Phase 6 — Write

Ask: "May I write `production/roadmap.md` and update milestone_target fields in `production/backlog.yaml`? [Y/N]"

On approval:
1. Write `production/roadmap.md` (see format below)
2. Update `milestone_target` for all stories in `production/backlog.yaml` where the epic's milestone was assigned in Phase 4

**roadmap.md format:**

```markdown
# Project Roadmap
Generated: [date] | Stage: [stage] | Active milestone: [name]
Velocity: [N] stories/sprint avg ([N]-sprint window) | Confidence: [low/medium/high]

## Milestone: vertical-slice
**Goal**: [from definition file, or "No definition — run /milestone-define init vertical-slice"]
**Status**: [active | planned | completed]

| Epic | Stories Done | Remaining | Est. Days | Target Sprint |
|------|-------------|-----------|-----------|--------------|
| economy | 5/6 | 1 | 1.0d | Sprint 6 |
| arena-visuals | 3/3 | 0 | — | Done ✓ |

**Completion horizon**: ~[N] sprints (est. [date range])

---

## Milestone: production
**Goal**: [from definition file or "No definition"]
**Status**: planned

| Epic | Stories Done | Remaining | Est. Days | Target Sprint |
|------|-------------|-----------|-----------|--------------|
| [epic] | 0/N | N | Xd | TBD |

**Completion horizon**: ~[N] sprints after vertical-slice closes

---

## Velocity History
| Sprint | Completed | Est. Days | Must-Have % | Notes |
|--------|-----------|-----------|-------------|-------|
| S1 | N | Nd | N% | |
| S2 | N | Nd | N% | |
...
| Avg | N | Nd | N% | |
```

---

## Mode: update

Re-derive roadmap after backlog changes (new stories, scope cuts, reprioritization).

### Phase 1 — Diff

Read `production/backlog.yaml`. Compare epic story counts and milestone_target assignments against `production/roadmap.md` (if it exists).

Surface changes:
- New epics added since last roadmap
- Epics with changed story counts
- Stories with changed milestone_target

### Phase 2 — Recalculate + Write

Re-run Phase 2 (velocity) and Phase 5 (horizon) with updated data.
Ask write approval. Write `production/roadmap.md`.
Does NOT re-prompt for milestone assignments — uses existing backlog.yaml `milestone_target` values.
If new unassigned epics exist: prompt for assignment before writing.

---

## Mode: view

Re-render `production/roadmap.md` from current backlog state without interactive prompts.

Read `production/backlog.yaml` and existing `production/roadmap.md`.
Recalculate completion horizon from current story counts and most recent velocity.
Ask write approval. Write updated `production/roadmap.md`.

Use when: story completions have accumulated but no epic-level changes occurred.
