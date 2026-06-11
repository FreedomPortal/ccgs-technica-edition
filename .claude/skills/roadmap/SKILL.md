---
name: roadmap
description: Scope-definition authority. Writes production/roadmap.yaml (machine-readable scope registry) and production/roadmap.md (human-readable narrative). Read by /create-epics, /backlog, /sprint-plan. Modes: init, update, view.
argument-hint: "[init | update | view]"
user-invocable: true
allowed-tools: Read, Glob, Write, AskUserQuestion
model: sonnet
---

# /roadmap

Defines project scope — what is being built and when. Writes two files:
1. `production/roadmap.yaml` — machine-readable scope registry (read by `/create-epics`, `/backlog`, `/sprint-plan`)
2. `production/roadmap.md` — human-readable narrative

**Principle:** `/roadmap` defines scope → `/create-epics` uses it → `/create-stories` fills it → `/backlog` tracks it.

**Modes:** `init` | `update` | `view`

---

## Mode: init

Interactive first-time scope definition. Does NOT require `production/backlog.yaml`.

### Phase 1 — Load project scope

Read:
- `design/gdd/systems-index.md` — authoritative system list, layers, status (required)
- `production/milestones/definitions/` — any existing milestone definition files (optional)
- `production/milestones/active.txt` — active milestone name (optional)
- `production/wishlist.yaml` — if exists, note items that could be future scope

Do NOT require `production/backlog.yaml` — it may not exist yet.

Report: "Found [N] systems in systems-index. [N] milestone definitions. [N] wishlist items."

If `design/gdd/systems-index.md` is missing:
> "systems-index.md not found. Create `design/gdd/systems-index.md` with a list of all game systems before running /roadmap init."

Stop.

### Phase 2 — Propose milestone groupings

Filter systems-index to Approved/Designed GDDs only (skip Draft/Concept).

For each qualifying system, propose a milestone target based on:
1. Layer (`foundation`/`core` → earliest active milestone; `presentation`/`feature` → later milestone)
2. Whether the system appears in any existing milestone definition file
3. Heuristic: core loop systems → current active milestone; content/polish → production; large/experimental → post-launch

Present grouped proposal:

```
## Proposed Milestone Scope

### [active-milestone-id] (active)
- [system-slug]   [layer]
- [system-slug]   [layer]

### production
- [system-slug]   [layer]

### post-launch
- [system-slug]   [layer — note if large scope]

### Unassigned (your input needed)
- [system-slug]   [layer — unclear milestone]

Accept? [A] Accept all  [E] Edit assignments  [N] Cancel
```

For any `[?]` items use `AskUserQuestion` to confirm milestone assignment before proceeding.

### Phase 3 — Velocity (if sprint history exists)

Glob `production/sprints/sprint-*.md`. If 2+ exist:
- Extract per-sprint story completion count, estimate_days completed, and must-have % done
- Compute rolling average (all available, cap at 5 sprints)
- Assign confidence: low (< 3 sprints or variance > 40%), medium (3–5 sprints, variance < 40%), high (5+ sprints, variance < 20%)

If fewer than 2 sprint files exist: note "No sprint history — completion horizon will be skipped. Run /roadmap update after first sprint completes."

### Phase 4 — Completion horizon (if velocity available)

For each milestone:
- If `production/backlog.yaml` exists (optional), sum remaining `estimate_days` for stories in that milestone's epics
- If backlog.yaml absent or epics not yet created: note "Epic stories not yet created — horizon estimate pending."

Compute sprints-to-complete per milestone at rolling average velocity.

### Phase 5 — Write

Ask: "May I write `production/roadmap.yaml` and `production/roadmap.md`?"

On approval, write both files.

**roadmap.yaml schema:**

```yaml
# Source of truth for project scope and milestone assignments.
# Written by /roadmap. Read by /create-epics, /backlog, /sprint-plan.
# NEVER edit milestone_target fields in backlog.yaml directly — update roadmap.yaml and run /roadmap update.

version: 1
generated: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
active_milestone: [id]

milestones:
  - id: vertical-slice
    label: "Vertical Slice"
    goal: "..."            # from milestone definition file, or user-authored
    status: active         # active | planned | completed
    in_scope:
      - slug: [system-slug]         # matches production/epics/[slug]/
        gdd: design/gdd/[slug].md
        layer: core                 # foundation | core | feature | presentation
        epic_status: not-started    # not-started | in-progress | done

unassigned:   # systems known from GDDs but not yet assigned to any milestone
  - gdd: design/gdd/[slug].md
    layer: feature
    note: "Created after roadmap — assign with /roadmap update"
```

**roadmap.md format:**

```markdown
# Project Roadmap
Generated: [date] | Stage: [stage] | Active milestone: [name]
[Velocity line if available: "Velocity: N stories/sprint avg (N-sprint window) | Confidence: low/medium/high"]

## Milestone: [label]
**Goal**: [goal text]
**Status**: active/planned/completed

| Epic/System | Layer | GDD | Epic Status | Est. Days Remaining |
|-------------|-------|-----|-------------|---------------------|
| [slug] | core | [link] | in-progress | 3.5d |
| [slug] | feature | [link] | not-started | 5.0d |

**Completion horizon**: [N sprints / "Pending — no sprint history yet"]

---

## Milestone: [next]
...

---

## Unassigned Systems
[list, or "None — all systems assigned."]

## Wishlist (not yet scoped)
[N items in wishlist not assigned to any milestone. Run `/wishlist view` to review.]
```

---

## Mode: update

Re-derive roadmap after new GDDs, epics, or stories are added.

### Phase 1 — Diff against current state

Read `production/roadmap.yaml`. If missing:
> "roadmap.yaml not found. Run `/roadmap init` first."
Stop.

**Check for new unassigned systems:**
- Read `design/gdd/systems-index.md`
- Compare system list (Approved/Designed only) against all `slug` entries across all milestones in roadmap.yaml
- Any system in systems-index but absent from roadmap.yaml → add to `unassigned:` list, then ask for milestone assignment via `AskUserQuestion`

**Check for epic_status drift:**
- Glob `production/epics/*/EPIC.md`
- Read `Status:` field from each
- Reconcile against `epic_status` in roadmap.yaml; flag changes

### Phase 2 — Recalculate velocity + horizon

Re-run Phase 3 and Phase 4 from init with updated data.

### Phase 3 — Write

Ask: "May I write `production/roadmap.yaml` and `production/roadmap.md`?"

On approval, write both files. Confirm: "Roadmap updated."

---

## Mode: view

Read-only. No file write.

Read `production/roadmap.yaml` and current epic statuses (glob `production/epics/*/EPIC.md`). Render the roadmap.md format to chat output with current epic_status values reflected.

---

## Collaborative protocol

- `init` is interactive — never auto-assign milestones without user confirmation
- `update` is semi-automatic — auto-detect drift, confirm before writing
- `roadmap.yaml` is the scope authority — `/create-epics` reads it, not the other way around
- Wishlist items are surfaced as "potential future scope" but never auto-promoted
- Never modify `production/backlog.yaml` — roadmap.yaml owns scope; backlog reads from it

---

## Recommended Next Steps

Verdict: COMPLETE — roadmap written.

- Run `/create-epics` to generate epic directories from roadmap scope
- Run `/backlog init` to build the story registry from current epic files
- Run `/export-status` for a velocity-based completion horizon
