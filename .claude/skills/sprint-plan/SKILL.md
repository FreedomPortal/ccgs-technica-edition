---
name: sprint-plan
description: "Generates a new sprint plan or updates an existing one based on the current milestone, completed work, and available capacity. Pulls context from production documents and design backlogs."
argument-hint: "[new|update|status] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
model: sonnet
context: |
  !ls production/sprints/ 2>/dev/null
---

## Phase 0: Parse Arguments

Extract the mode argument (`new`, `update`, or `status`) and resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

**Review mode check** (before gates run):
- Read `production/review-mode.txt` if it exists. Use that mode.
- If the file doesn't exist and this is a `new` sprint: use `AskUserQuestion`:
  - Prompt: "No review mode is set. Which review depth would you like for this sprint?"
  - Options:
    - `[A] full — spawn all director and lead gates`
    - `[B] lean — skip non-phase-gate director reviews (recommended for most sprints)`
    - `[C] solo — skip all gate spawning`
  - After selection: write `production/review-mode.txt` with the chosen mode. Say: "Review mode set to [mode] and saved to production/review-mode.txt."
- If the file doesn't exist and this is NOT a `new` sprint (e.g., updating an existing sprint): default to `lean` silently.

---

## Phase 0.5: Backlog Read

Check for `production/backlog.yaml`.

**If missing**: continue with GDD inference in Phase 1 (degraded mode). Note:
> "No backlog.yaml found — falling back to GDD scan for story candidates. Run `/backlog init` to enable backlog-driven planning."

**If found**: read `production/backlog.yaml`. Identify story candidates in this order:

1. `status: carried-over` — not completed from a previous sprint; offer as first candidates
2. `status: ready` — dependencies met, awaiting sprint planning
3. `status: backlog` — not yet sprinted; surface grouped by `milestone_target`

**Active milestone prioritization**: If `production/milestones/active.txt` exists, read the active milestone name. Within the backlog candidate list, stories where `milestone_target` matches the active milestone appear first, marked `[active milestone]`. Stories targeting other milestones appear after, marked with their `milestone_target` value.

Present to the user before Phase 1 (skip if backlog has no candidates in the above statuses):
> "Backlog candidates for Sprint N: [N carried-over, N ready, N backlog]. Use these as primary story list? [Y/N]"

GDD scan in Phase 1 then runs as a **secondary check** — surfaces new stories not yet in the backlog.

---

## Phase 1: Gather Context

1. **Read the current milestone** from `production/milestones/`.

2. **Read `production/roadmap.yaml`** (if it exists):
   - Extract `active_milestone` — confirm it matches the milestone from step 1.
   - For the active milestone, read each entry's `slug` and `epic_status`.
   - Flag any system with `epic_status: in-progress` — these are incomplete epics
     that may need stories this sprint.
   - Flag any system with `epic_status: done` that has stories in backlog.yaml still
     `in-sprint` or `ready` — this is a status mismatch worth surfacing to the user.
   - Note all in-progress epics for Phase 1c (interaction coverage check).
   - If roadmap.yaml is missing: continue — degraded mode, no epic status signal.

3. **Read the previous sprint** (if any) from `production/sprints/` to
   understand velocity and carryover.

4. **Scan design documents** in `design/gdd/` for features tagged as ready
   for implementation.

5. **Check the risk register** at `production/risk-register/`.

6. **Check for pipeline tooling work** — `Glob` for `tools/TOOL_SPEC.md`.
   - **Found**: Read it to identify the tool name and purpose. Then ask:
     > "I found `tools/TOOL_SPEC.md` — [tool name]: [one-line purpose]. How many
     > sprint points do you want to allocate to pipeline tooling this sprint?
     > What work needs doing? (Enter 0 or skip to omit tooling from this sprint.)"
     Store the allocation and task descriptions for use in Phase 2.
   - **Not found**: Continue — tooling section is omitted from the sprint plan.

---

## Phase 1b: Sprint Goal Dependency Audit

**Run this phase before generating any story list.** It prevents the sprint goal that requires
prerequisites that were never scoped, making the goal structurally unachievable from day one.

**Step 1 — State the sprint goal explicitly.**
If the sprint goal comes from the milestone doc, quote it. If not defined yet,
prompt the user with `AskUserQuestion` before continuing.

**Step 2 — Identify what the sprint goal requires to be demonstrable.**
For each sprint goal category, check the corresponding prerequisites:

| Goal type | Prerequisites to verify |
|-----------|------------------------|
| Playable game loop / vertical slice | All entry-point scene/level files in the loop path must exist |
| Feature "works end-to-end" | Scene/level hosting the feature must exist |
| "Players can experience X" | UX flow for X must have a runnable entry point |
| Logic / systems only (no player-visible demo) | No scene prerequisite — skip this audit |

**Step 3 — Check prerequisites exist.**
For any "playable" or "end-to-end" goal, `Glob` for the required scene/level files.
Use the pattern matching the configured engine:

| Engine | Scene file pattern |
|--------|--------------------|
| Godot | `src/**/*.tscn` |
| Unity | `Assets/**/*.unity` |
| Unreal | `Content/**/*.umap` |
| Unknown | Check `CLAUDE.md` → Technology Stack for engine, then use matching pattern |

Compare the found files against what the sprint goal requires.

**Step 4 — Surface missing prerequisites.**
If any prerequisite is missing AND is not already in the current draft story list as a must-have:

> ⚠️ **Goal prerequisite missing: `[path/to/scene-or-level-file]`**
> The sprint goal "[goal]" requires this scene/level to exist. It is not in the codebase
> and is not scoped as a must-have story. Without it, the sprint goal is
> structurally unachievable.

Use `AskUserQuestion`:
- Prompt: "Missing prerequisite: [file]. How do you want to handle this?"
- Options:
  - `[A] Add it as a must-have story (Recommended) — scope the scene/level creation into this sprint`
  - `[B] Downgrade the sprint goal — remove the runnable-loop requirement`
  - `[C] Accept the risk — I know the goal may not be fully demonstrable this sprint`

If [A]: add a scene/level-creation story to the must-have list before Phase 2 begins.
If [B]: rephrase the sprint goal to not promise a runnable demo (e.g., "Implement logic layer for X" instead of "Playable X loop").
If [C]: add a KNOWN RISK block to the sprint plan:
```markdown
> ⚠️ **Known risk:** Sprint goal requires `[file]` which does not exist. Sprint may
> not produce a runnable demo. Playtest sessions dependent on this scene/level are blocked.
```

**Step 5 — Proceed to Phase 2 with prerequisites resolved.**

---

## Phase 2: Generate Output

For `new`:

**Generate a sprint plan** following this format and present it to the user. Do NOT ask to write yet — the producer feasibility gate (Phase 4) runs first and may require revisions before the file is written.

```markdown
# Sprint [N] — [Start Date] to [End Date]

## Sprint Goal
[One sentence describing what this sprint achieves toward the milestone]

## Capacity
- Total days: [X]
- Buffer (20%): [Y days reserved for unplanned work]
- Available: [Z days]
- Tooling allocation: [N points]  *(omit this line if no tooling work this sprint)*

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

## Pipeline Tools  *(omit this section if tools/TOOL_SPEC.md not found or allocation is 0)*
| ID | Task | Est. Points | Acceptance Criteria |
|----|------|-------------|-------------------|

*Tasks here draw from the tooling allocation, not the game capacity pool.*

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|

## Dependencies on External Factors
- [List any external dependencies]

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-[N].md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
```

**Immediately after generating the plan output above**, write the draft to disk:

```
production/session-state/drafts/sprint-[N]-draft-YYYYMMDD-HHMMSS.md
```

Create `production/session-state/drafts/` if it does not exist.
This draft survives crashes before the Phase 4 approval gate.

For `update`:

**Update an existing sprint plan**:

1. Read the most recent sprint plan from `production/sprints/`.
2. Present the current story list with their current statuses from `production/sprint-status.yaml`.
3. Ask the user what to change: stories to add, remove, reprioritize, or re-estimate. Use `AskUserQuestion` to gather changes.
4. Apply the changes and re-present the full revised plan for review.
5. Re-run the producer feasibility gate (Phase 4) on the revised plan.
6. Write the updated markdown plan and yaml together (same approval as `new` mode).

Note: `update` mode does not reset story statuses. Stories already marked `in-progress` or `done` keep their status. Only `backlog` and `ready-for-dev` stories can be removed or reprioritized freely.

For `status`:

**Generate a status report**:

```markdown
# Sprint [N] Status -- [Date]

## Progress: [X/Y tasks complete] ([Z%])

### Completed
| Task | Completed By | Notes |
|------|-------------|-------|

### In Progress
| Task | Owner | % Done | Blockers |
|------|-------|--------|----------|

### Not Started
| Task | Owner | At Risk? | Notes |
|------|-------|----------|-------|

### Blocked
| Task | Blocker | Owner of Blocker | ETA |
|------|---------|-----------------|-----|

## Burndown Assessment
[On track / Behind / Ahead]
[If behind: What is being cut or deferred]

## Emerging Risks
- [Any new risks identified this sprint]
```

---

## Phase 2.5: Framework Task Filter

**Run this after the story list is assembled, before writing anything.**

Scan every story in the draft plan for framework-related signals. A story is **framework-related** if any of these match:

| Signal | Example |
|--------|---------|
| Name contains `SKILL.md`, a slash-command (e.g. `/design-review`), `framework`, or `CCGS` | "Update /design-review SKILL.md" |
| Name contains `agent` or `hook` (referring to dev tooling, not game AI) | "Update session-start hook", "Fix producer agent memory" |
| File path is under `.claude/` or in a `foundation` epic | `production/epics/foundation/story-002-*.md` |
| Owner is `"developer"` AND name describes modifying dev tooling | "Add process rules to skill" |

**Note**: game data pipeline tools (`tools/`) are NOT framework tasks — they have their own `Pipeline Tools` section and are not affected by this filter.

If **no** framework stories are detected, skip this phase silently.

If **one or more** framework stories are detected, present them and use `AskUserQuestion`:
- Prompt: "These stories modify the development framework (skills, CCGS tooling), not the game. Include in this sprint?"
- List each detected story with a checkbox option per story
- Also offer:
  - `[All] Include all framework stories`
  - `[None] Exclude all framework stories`

For any story the user excludes: remove it from the draft plan's task tables and from the sprint-status.yaml draft. Do not silently drop it — note at the bottom of the plan:

```markdown
> **Excluded (framework):** The following stories were removed from this sprint — they modify dev tooling, not game content:
> - [story name]
```

Framework stories are not lost — they persist in their epic files and can be picked up outside the sprint cadence.

---

## Phase 3: Prepare Sprint Status File

After generating a new sprint plan, also prepare the `production/sprint-status.yaml` content.
This is the machine-readable source of truth for story status — read by
`/sprint-status`, `/story-done`, and `/help` without markdown parsing.

**Do not write the yaml yet** — hold it in context. The producer feasibility gate (Phase 4) may revise the story list. Both files will be written together after Phase 4 in a single write approval.

Format:

```yaml
# Auto-generated by /sprint-plan. Updated by /story-done and /dev-story.
# DO NOT edit manually — use /story-done to update story status.
#
# Status value mapping (yaml ↔ story file Status field):
#   backlog        ↔  Not Started
#   ready-for-dev  ↔  Ready
#   in-progress    ↔  In Progress
#   review         ↔  In Review
#   done           ↔  Complete
#   blocked        ↔  Blocked

sprint: [N]
goal: "[sprint goal]"
start: "[YYYY-MM-DD]"
end: "[YYYY-MM-DD]"
generated: "[YYYY-MM-DD]"
updated: "[YYYY-MM-DD]"

stories:
  - id: "[epic-story, e.g. 1-1]"
    name: "[story name]"
    file: "[production/stories/path.md]"
    priority: must-have        # must-have | should-have | nice-to-have | tooling
    status: ready-for-dev      # backlog | ready-for-dev | in-progress | review | done | blocked
    owner: ""
    estimate_days: 0
    blocker: ""
    completed: ""
```

Initialize each story from the sprint plan's task tables:
- Must Have tasks → `priority: must-have`, `status: ready-for-dev`
- Should Have tasks → `priority: should-have`, `status: backlog`
- Nice to Have tasks → `priority: nice-to-have`, `status: backlog`
- Pipeline Tools tasks → `priority: tooling`, `status: ready-for-dev` (omit `file` field; set `id` to `T[N]-001`, `T[N]-002`, etc.; draw from tooling capacity pool, not game capacity)

For `update`: read the existing `sprint-status.yaml`, carry over statuses for
stories that haven't changed, add new stories, remove dropped ones.

---

## Phase 4: Producer Feasibility Gate

**Review mode check** — apply before spawning PR-SPRINT:
- `solo` → skip. Note: "PR-SPRINT skipped — Solo mode." Proceed to Phase 5 (QA plan gate).
- `lean` → skip (not a PHASE-GATE). Note: "PR-SPRINT skipped — Lean mode." Proceed to Phase 5 (QA plan gate).
- `full` → spawn as normal.

Before finalising the sprint plan, spawn `producer` via Task using gate **PR-SPRINT** (`.claude/docs/director-gates.md`).

Pass: proposed story list (titles, estimates, dependencies), total team capacity in hours/days, any carryover from the previous sprint, milestone constraints and deadline.

Present the producer's assessment.

If UNREALISTIC: revise the story selection (defer stories to Should Have or Nice to Have) and re-present the updated plan before asking for write approval.

If CONCERNS, use `AskUserQuestion`:
- Prompt: "Producer flagged concerns with this sprint plan. How do you want to proceed?"
- Options:
  - `[A] Proceed as planned — I accept the risk`
  - `[B] Adjust scope — defer some Should Have stories`
  - `[C] Extend the sprint timeline`

If [A]: proceed to write approval.
If [B]: revise the story list, re-present the updated plan, then proceed to write approval.
If [C]: adjust sprint dates and capacity, re-present the updated plan, then proceed to write approval.

After handling the producer's verdict, ask: "May I write the sprint plan to `production/sprints/sprint-[N].md` and `production/sprint-status.yaml`?" If yes, write both files (creating directories as needed). Verdict: **COMPLETE** — sprint plan and status file created. If no: Verdict: **BLOCKED** — user declined write.

After writing, add:

> **Scope check:** If this sprint includes stories added beyond the original epic scope, run `/scope-check [epic]` to detect scope creep before implementation begins.

**Backlog sync**: If `production/backlog.yaml` exists, update it silently after write approval:
- For each story in the new sprint: if already in backlog → set `status: in-sprint`; if not in backlog → add new entry with `status: in-sprint`, `sprint: N`, and metadata from the sprint-status.yaml entry.
No separate confirmation needed — covered by the write approval above.

---

## Phase 5: QA Plan Gate

Before closing the sprint plan, check whether a QA plan exists for this sprint.

Use `Glob` to look for `production/qa/qa-plan-sprint-[N].md` or any file in `production/qa/` referencing this sprint number.

**If a QA plan is found**: note it in the sprint plan output — "QA Plan: `[path]`" — and proceed.

**If no QA plan exists**: do not silently proceed. Surface this explicitly:

> "This sprint has no QA plan. A sprint plan without a QA plan means test requirements are undefined — developers won't know what 'done' looks like from a QA perspective, and the sprint cannot pass the Production → Polish gate without one.
>
> Run `/qa-plan sprint` now, before starting any implementation. It takes one session and produces the test case requirements each story needs."

Use `AskUserQuestion`:
- Prompt: "No QA plan found for this sprint. How do you want to proceed?"
- Options:
  - `[A] Run /qa-plan sprint now — I'll do that before starting implementation (Recommended)`
  - `[B] Skip for now — I understand QA sign-off will be blocked at the Production → Polish gate`

If [A]: close with "Sprint plan written. Run `/qa-plan sprint` next — then begin implementation."
If [B]: add a warning block to the sprint plan document:

```markdown
> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA
> sign-off report, which requires a QA plan.
```

---

## Phase 6: Next Steps

After the sprint plan is written and QA plan status is resolved:

- `/qa-plan sprint` — **required before implementation begins** — defines test cases per story so developers implement against QA specs, not a blank slate
- `/story-readiness [story-file]` — validate a story is ready before starting it
- `/dev-story [story-file]` — begin implementing the first story
- `/sprint-status` — check progress mid-sprint
- `/scope-check [epic]` — verify no scope creep before implementation begins

**Review mode configuration:** All director gates (producer feasibility, QA review, code review) respect the project review mode. The review mode is set in Phase 0 when the file does not exist (for `new` sprints), or can be overridden per-run with `--review full|lean|solo` as an argument. The file `production/review-mode.txt` contains one of:
- `lean` — skip automated director gates (default if file is absent — fastest for solo dev)
- `full` — run all director gates as spawned sub-agents
- `solo` — skip all gates unconditionally (single-developer, no review)

This file is read by `/sprint-plan`, `/story-readiness`, `/story-done`, and other skills at startup.
