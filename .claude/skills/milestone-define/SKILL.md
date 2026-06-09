---
name: milestone-define
description: Create or update milestone definition files — scope contracts that specify what a build includes, excludes, quality bar, and exit criteria. Modes: init [name], list, activate [name].
model: sonnet
---

# /milestone-define

Manages `production/milestones/definitions/[name].md` — forward-looking scope contracts.

**Scope contracts vs milestone review docs:**
- `production/milestones/definitions/[name].md` — written *before* the milestone, defines what it means
- `production/milestones/[date]-review.md` — written *after* the gate, records what happened

---

## Standard Milestone Set

| Name | Build type | Player/stakeholder promise |
|------|-----------|--------------------------|
| `prototype` | Throwaway | "Does this mechanic feel fun?" |
| `vertical-slice` | Internal playtest | "Does the full loop work?" |
| `demo` | External players | "Is this worth wishlisting?" |
| `alpha` | Internal/closed | "Is the game feature-complete?" |
| `beta` | Wide/public | "Is this almost shippable?" |
| `release` | All players | "Ship it." |

Custom milestones (e.g. `early-access`) may be added. Not all projects need all six.

---

## Mode: init [name]

Create or update a milestone definition file.

### Phase 1 — Guard

Check for existing `production/milestones/definitions/[name].md`.

If found: "Definition for [name] already exists. Overwrite? [Y/N]"
- N: stop.

### Phase 2 — Gather

Use `AskUserQuestion` to gather definition fields:

1. **Goal statement** — one sentence player/stakeholder promise for this build
2. **In-scope epics/systems** — which systems must be complete for this milestone (read `production/backlog.yaml` for epic list if available; present as checklist)
3. **Out-of-scope list** — what is explicitly deferred and why
4. **Quality bar** — what level of polish/stability is required (e.g. "loop-complete, rough edges accepted")
5. **Exit criteria** — 3–6 testable conditions that must be true to advance (e.g. "player can complete full loop without crash")
6. **Gate skill** — which `/gate-check [stage]` evaluates this milestone

Batch fields 1–4 into one `AskUserQuestion` call; fields 5–6 in a second call.

### Phase 3 — Write

Ask: "May I write `production/milestones/definitions/[name].md`? [Y/N]"

```markdown
# Milestone: [name]
**Type**: [build type from standard set, or custom]
**Status**: active | planned | completed

## Goal
[One sentence player/stakeholder promise]

## In Scope
Epics/systems that must be complete for this milestone:
- [epic or system name]
- [epic or system name]

## Out of Scope
Explicitly deferred (with reason):
- [feature] — deferred to [milestone-name]: [reason]

## Quality Bar
[What level of polish/stability is required]

## Exit Criteria
- [ ] [Testable condition 1]
- [ ] [Testable condition 2]
- [ ] [Testable condition 3]

## Gate
`/gate-check [stage]` — run to evaluate this milestone.
```

After write: suggest `/milestone-define activate [name]` if this is the current target.

---

## Mode: list

Read `production/milestones/definitions/`.

Read `production/milestones/active.txt` (if exists) for active milestone name.

Output:

```
Milestone Definitions
─────────────────────────────────────────────
Active: [name or "none set"]

  [name]     [status]    [goal — first sentence]
  [name]     [status]    [goal — first sentence]
  ...

Run /milestone-define activate [name] to set the active milestone.
Run /roadmap view to see epic-to-milestone mapping.
```

If `production/milestones/definitions/` is empty or missing: "No milestone definitions found. Run `/milestone-define init [name]` to create the first one."

---

## Mode: activate [name]

Set the active milestone. Skills that are scope-aware read this value.

1. Verify `production/milestones/definitions/[name].md` exists. If not: "No definition found for [name]. Run `/milestone-define init [name]` first."
2. Write `production/milestones/active.txt` with content: `[name]`
3. Update the target definition file's `Status` field to `active` (set all others to `planned` or `completed` as appropriate).
4. Confirm: "Active milestone set to: [name]"

---

## Scope-Aware Skills

The following skills read `production/milestones/active.txt` when available:
- `/gate-check` — evaluates only in-scope features; lists deferred features separately
- `/backlog view --milestone [name]` — filters to stories tagged for this milestone
- `/sprint-plan` Phase 0.5 — prioritizes stories matching active milestone
- `/architecture-review` — classifies scope-boundary conflicts as `[SCOPE-EXPANSION]`

---

## File Location

```
production/
  milestones/
    active.txt                      ← current target milestone name
    definitions/
      vertical-slice.md             ← forward-looking scope contract
      demo.md
      alpha.md
    vertical-slice-review-2026-06-09.md   ← backward-looking gate report (existing)
```
