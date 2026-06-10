---
name: export-status
description: Generate a production status report with velocity metrics, predictability score, scope creep rate, and milestone completion horizon. Modes: full (complete report), lean (key metrics + horizon), metrics (raw numbers only). Output: production/reports/status-YYYY-MM-DD.md.
model: sonnet
---

# /export-status

Generates a status report from sprint history, backlog state, and milestone definitions.

**Inputs:**
- `production/sprints/sprint-*.md` — velocity history (required for metrics; gracefully absent)
- `production/backlog.yaml` — story counts, milestone targets, statuses (recommended)
- `production/sprint-status.yaml` — current sprint state, blocked count (optional)
- `production/milestones/active.txt` — active milestone name (optional)
- `production/milestones/definitions/[name].md` — exit criteria progress (optional)

**Output:** `production/reports/status-[YYYY-MM-DD].md`

---

## Modes

- **`full`** — complete report: velocity tables, predictability, scope creep, blockers, milestone exit criteria progress
- **`lean`** — summary: headline metrics + completion horizon + blockers only
- **`metrics`** — structured numbers only (YAML-like block), no narrative; for programmatic use

Default mode when no argument: `full`.

---

## Phase 1 — Load Data

### Sprint files

Glob `production/sprints/sprint-*.md`. For each sprint file, extract:

1. **Sprint number** — from filename or header
2. **Sprint start date** and **end date** (or duration in days)
3. **Stories planned at sprint start** — count of stories listed at planning time
   - Read from "Stories" or "Planned" section near the top of each sprint file
4. **Stories completed** (`status: done`) — count + sum of `estimate_days`
5. **Must-have stories planned** — stories marked `priority: must-have` or `[MUST]`
6. **Must-have stories completed**
7. **Mid-sprint additions** — stories added after sprint started (look for `added:` field or annotation)

If a sprint file lacks a field, record as `null` for that sprint. Do not skip the sprint.

Cap at last 5 sprints for rolling calculations; use all available for the velocity history table.

### Backlog

If `production/backlog.yaml` exists: read all stories. Group by:
- `status`: `done` | `in-progress` | `ready` | `backlog` | `carried-over`
- `milestone_target`: group remaining (`not done`) stories per milestone

### Current sprint

If `production/sprint-status.yaml` exists: read current sprint number, count `status: blocked` entries.

### Active milestone

If `production/milestones/active.txt` exists: read milestone name.
If the corresponding definition file exists at `production/milestones/definitions/[name].md`: read Exit Criteria section.

---

## Phase 2 — Compute Metrics

### Velocity

**Stories per sprint** (rolling average):
- Use last 3 sprints where `completed` is not null
- Also compute 5-sprint average if 5+ sprints exist
- Std dev across the window used for date range confidence

**Estimate-days per sprint** (rolling average):
- Same window; sum of `estimate_days` for completed stories

**Confidence level:**

| Condition | Confidence |
|-----------|-----------|
| Fewer than 3 sprints with data | LOW |
| 3–4 sprints, std dev / mean ≤ 40% | MEDIUM |
| 5+ sprints, std dev / mean ≤ 20% | HIGH |
| Any window, std dev / mean > 40% | LOW |

### Predictability score

Per sprint: `predictability = (must-have completed / must-have planned) × 100`

Rolling average across the velocity window. If any sprint has `null` must-have data, exclude it from average (do not substitute 0).

Report as: `[avg]% ([min]%–[max]% range over last N sprints)`

### Scope creep rate

Per sprint: `creep_rate = mid-sprint additions / stories planned at start`

Rolling average across velocity window. If `mid-sprint additions` data not available for a sprint, exclude it.

Report as: `[avg]% per sprint` or `"Insufficient data"` if fewer than 2 sprints have addition counts.

### Completion horizon

For each milestone with remaining stories:

```
remaining_stories = count of stories in backlog.yaml where:
  status NOT IN (done) AND milestone_target = [milestone name]

sprints_needed = remaining_stories / velocity_avg (3-sprint rolling)
horizon_lo = today + (sprints_needed - 1 std_dev) × sprint_duration_days
horizon_hi = today + (sprints_needed + 1 std_dev) × sprint_duration_days
```

Use 7-day sprint duration if sprint files don't specify duration.

If `velocity_avg == 0` or no velocity data: report `"Cannot estimate — no velocity data"`.

---

## Phase 3 — Format Report

### `full` mode

```markdown
# Production Status Report
Generated: [date] | Stage: [stage from production/stage.txt or "Unknown"] | Active milestone: [name or "none"]

## Velocity
Rolling average (last [N] sprints): **[X] stories/sprint** ([Y] est-days/sprint)
5-sprint avg: [X] stories/sprint | Confidence: [LOW/MEDIUM/HIGH]

| Sprint | Completed | Est-Days | Must-Have % | Mid-Sprint Adds | Notes |
|--------|-----------|----------|-------------|-----------------|-------|
| S[N]   | [N]       | [N]d     | [N]%        | [N]             |       |
...
| Avg    | [N]       | [N]d     | [N]%        | [N]             |       |

## Predictability
[avg]% — [interpretation: "Reliable" ≥80%, "Variable" 60–79%, "Unreliable" <60%]
Range: [min]%–[max]% over last [N] sprints

## Scope Creep
[avg]% per sprint — [interpretation: "Controlled" ≤10%, "Moderate" 11–25%, "High" >25%]
[Or: "Insufficient data"]

## Milestone Progress

### [milestone name] [active ★ or planned]
Remaining: [N] stories | Est-days: [N]d
Completion horizon: ~[N] sprints (est. [date-lo] – [date-hi]) | Confidence: [level]

Exit Criteria:
- [x] [criterion — done]
- [ ] [criterion — open]
[Or: "(No definition file — run /milestone-define init [name])"]

### [next milestone]
...

## Current Sprint Snapshot
Sprint [N] | Blocked: [N] stories
[Or: "(sprint-status.yaml not found)"]

## Blockers
[List blocked stories from sprint-status.yaml with story ID and epic]
[Or: "None"]
```

### `lean` mode

```markdown
# Status: [date]
Active milestone: [name] | Stage: [stage]

Velocity: [X] stories/sprint ([N]-sprint avg) | Confidence: [level]
Predictability: [avg]% | Scope creep: [avg]%/sprint
Horizon ([milestone]): ~[N] sprints (est. [date-lo]–[date-hi])

Blocked: [N] stories
```

### `metrics` mode

```
velocity_avg_3sprint: [N]
velocity_avg_5sprint: [N]
velocity_confidence: [LOW|MEDIUM|HIGH]
estimate_days_avg: [N]
predictability_avg_pct: [N]
scope_creep_avg_pct: [N]
active_milestone: [name]
remaining_stories_active: [N]
remaining_days_active: [N]
horizon_lo: [YYYY-MM-DD]
horizon_hi: [YYYY-MM-DD]
blocked_count: [N]
report_date: [YYYY-MM-DD]
```

---

## Phase 4 — Write

Ask: "May I write `production/reports/status-[date].md`? [Y/N]"

On approval: write the formatted report. Create `production/reports/` if it doesn't exist.

After write: print the lean summary to chat regardless of mode, so the key numbers are visible in the session.

---

## Graceful Degradation

| Missing input | Behavior |
|---------------|----------|
| No sprint files | All velocity/predictability/scope metrics = "No data" |
| No backlog.yaml | Milestone horizon = "No backlog data"; use sprint files only for velocity |
| No sprint-status.yaml | Blockers = "(sprint-status.yaml not found)" |
| No active.txt | Active milestone = "none set"; show all milestones with remaining stories |
| No milestone definition | Exit criteria section = "(No definition — run /milestone-define init [name])" |
| Fewer than 2 sprints | Confidence = LOW; still compute what's available |

Never fail hard. Always produce a partial report.

---

## Validation Sanity Check

After computing velocity, verify the formulas produce plausible output:

- 3-sprint avg should be lower than the all-time avg if early sprints were setup-heavy outliers
- Confidence should be LOW when variance across sprints exceeds 40%
- Predictability index should be < 1.0 when must-have % data is missing from sprint files

Never fail hard. Always produce a partial report with available data.
