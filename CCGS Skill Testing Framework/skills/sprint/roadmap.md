# Skill Spec: /roadmap
> **Category**: sprint
> **Priority**: medium
> **Spec written**: 2026-06-11

## Skill Summary

/roadmap is the scope-definition authority for the CCGS:TE framework. It writes two files — `production/roadmap.yaml` (machine-readable scope registry consumed by `/create-epics`, `/backlog`, and `/sprint-plan`) and `production/roadmap.md` (human-readable narrative) — across three modes: `init` (interactive first-time setup), `update` (re-derive after GDD or epic changes), and `view` (read-only chat render). In `init` mode it loads the systems index, proposes milestone groupings with user confirmation, optionally computes velocity from sprint history, optionally estimates completion horizons from backlog data, and then gates on "May I write" before producing either file. `update` mode diffs current roadmap.yaml against live systems and epic status, recalculates velocity, and applies the same write gate. `view` mode never writes. The skill explicitly forbids auto-promoting wishlist items or modifying `production/backlog.yaml`.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model`)
- [x] 2+ phase headings found (Mode: init has Phase 1–5; Mode: update has Phase 1–3; Mode: view is a flat section)
- [x] At least one verdict keyword present (`Verdict: COMPLETE — roadmap written.`)
- [x] If allowed-tools includes Write/Edit: "May I write" language present (Phase 5 of init: "May I write `production/roadmap.yaml` and `production/roadmap.md`?"; update Phase 3: same)
- [x] Next-step handoff section present (`## Recommended Next Steps` with `/create-epics`, `/backlog init`, `/export-status`)

---

## Director Gate Checks

N/A — skill contains no explicit director-review invocation or PR-SPRINT / PR-MILESTONE gate block. The Collaborative Protocol section is author-facing guidance, not a gate trigger.

---

## Test Cases

### Case 1: Happy Path — `init` with full inputs

**Fixture**
- `design/gdd/systems-index.md` exists with 4 systems (2 Approved/core, 1 Approved/feature, 1 Draft)
- `production/milestones/definitions/vertical-slice.md` exists
- `production/milestones/active.txt` = `vertical-slice`
- `production/wishlist.yaml` exists with 2 items
- `production/sprints/sprint-01.md` and `sprint-02.md` exist
- `production/backlog.yaml` exists with estimate_days populated

**Expected behavior**
1. Phase 1 reports: "Found 3 systems in systems-index [Approved/Designed only]. 1 milestone definitions. 2 wishlist items." (Draft system excluded from active proposals)
2. Phase 2 presents grouped proposal with 2 core systems under `vertical-slice`, 1 feature system under `production`, no Unassigned items; shows `[A] Accept all [E] Edit assignments [N] Cancel`
3. Phase 3 computes rolling average velocity from 2 sprints; assigns confidence `low` (< 3 sprints)
4. Phase 4 computes sprint-to-complete per milestone using backlog estimate_days
5. Phase 5 asks "May I write `production/roadmap.yaml` and `production/roadmap.md`?" — on approval writes both
6. Output ends with Recommended Next Steps block

**Assertions**
- [ ] Phase 1 report line matches stated format
- [ ] Draft-status systems excluded from milestone proposals
- [ ] Proposal block renders with Accept/Edit/Cancel options
- [ ] Velocity confidence = `low` when only 2 sprints present
- [ ] Write gate fires before any file is touched
- [ ] Both files written only after approval
- [ ] roadmap.yaml contains `version`, `generated`, `active_milestone`, `milestones` keys
- [ ] roadmap.md contains velocity line and completion horizon line
- [ ] Recommended Next Steps present in output

**Verdict**: PASS

---

### Case 2: Failure/Blocked — missing `systems-index.md`

**Fixture**
- `design/gdd/systems-index.md` does not exist
- All other files absent or irrelevant

**Expected behavior**
1. Phase 1 detects missing file
2. Emits exact message: "systems-index.md not found. Create `design/gdd/systems-index.md` with a list of all game systems before running /roadmap init."
3. Stops — no further phases execute, no AskUserQuestion, no writes

**Assertions**
- [ ] Exact stop message emitted (no paraphrasing)
- [ ] No Phase 2 proposal rendered
- [ ] No write gate triggered
- [ ] No files written

**Verdict**: BLOCKED

---

### Case 3: Mode Variant — `view` mode

**Fixture**
- `production/roadmap.yaml` exists with 2 milestones and 3 systems
- `production/epics/combat/EPIC.md` exists with `Status: in-progress`
- `production/epics/movement/EPIC.md` exists with `Status: not-started`

**Expected behavior**
1. Reads `production/roadmap.yaml`
2. Globs `production/epics/*/EPIC.md` and reads Status fields
3. Renders roadmap.md table format to chat output with live epic_status values (reflecting `in-progress` for combat)
4. No write gate, no files written

**Assertions**
- [ ] Output rendered to chat only, no files written
- [ ] epic_status values reflect current EPIC.md contents, not stale roadmap.yaml values
- [ ] No "May I write" prompt issued
- [ ] No AskUserQuestion called

**Verdict**: PASS (read-only)

---

### Case 4: Edge Case — `update` mode with no existing `roadmap.yaml`

**Fixture**
- `production/roadmap.yaml` does not exist
- `design/gdd/systems-index.md` exists

**Expected behavior**
1. Phase 1 (update) reads `production/roadmap.yaml` — file missing
2. Emits: "roadmap.yaml not found. Run `/roadmap init` first."
3. Stops immediately — no diff, no velocity recalculation, no write

**Assertions**
- [ ] Exact stop message emitted
- [ ] No Phase 2 recalculation attempted
- [ ] No write gate triggered
- [ ] Skill does not fall through to `init` behavior

**Verdict**: BLOCKED

---

### Case 5: Most Relevant Variant — `init` with unassigned systems requiring user input

**Fixture**
- `design/gdd/systems-index.md` exists with 3 Approved systems: 1 `core`, 1 `feature`, 1 `presentation` (no existing milestone definition covers the presentation system)
- `production/milestones/active.txt` = `vertical-slice`
- No sprint history, no backlog.yaml

**Expected behavior**
1. Phase 2 heuristic places `core` under active milestone, `feature` under `production`; `presentation` system has unclear milestone → listed under `Unassigned (your input needed)`
2. For the unassigned item, `AskUserQuestion` is used to confirm milestone assignment before proceeding (not auto-assigned)
3. Phase 3 notes "No sprint history — completion horizon will be skipped. Run /roadmap update after first sprint completes."
4. Phase 4 notes "Epic stories not yet created — horizon estimate pending."
5. Phase 5 write gate fires; on approval both files written; roadmap.yaml `unassigned:` block is empty (user assigned the item) or populated if user deferred

**Assertions**
- [ ] `AskUserQuestion` invoked for the unassigned presentation system
- [ ] Proposal not auto-finalized without user confirmation of the `[?]` item
- [ ] Phase 3 skip message matches stated exact text
- [ ] Phase 4 pending message present
- [ ] roadmap.yaml written with correct schema including `unassigned:` key
- [ ] No wishlist items auto-promoted to any milestone

**Verdict**: PASS

---

## Protocol Compliance

- [x] "May I write" before file writes — explicitly stated in init Phase 5 and update Phase 3; view mode has no write
- [x] Presents findings before approval — Phase 2 proposal block presented and accepted before Phase 5 write gate; update mode detects drift and flags changes before write gate
- [x] Ends with next step — `## Recommended Next Steps` block with three successor skill calls
- [x] No auto-create without approval — Collaborative Protocol section explicitly states `init` is interactive, `update` confirms before writing; wishlist items never auto-promoted

---

## Coverage Notes

**SP1** — COVERED. Init Phase 1 reads `production/milestones/definitions/` and `production/milestones/active.txt`; Phase 3 globs `production/sprints/sprint-*.md`; update Phase 1 reads `production/roadmap.yaml` and globs `production/epics/*/EPIC.md`. Multiple sprint/milestone paths read before output.

**SP2** — NOT COVERED. No PR-SPRINT or PR-MILESTONE gate block is present anywhere in the skill. The skill has no full/lean/solo mode distinction. This is a coverage gap: there is no written instruction gating behavior on project stage or director-review triggers.

**SP3** — COVERED. roadmap.yaml schema and roadmap.md table format are explicitly specified with fixed keys and column headers. Output is structured, not free prose.

**SP4** — COVERED. "May I write" gates present in both write-capable modes (init Phase 5, update Phase 3). `view` mode has no write path. Collaborative Protocol section explicitly forbids modifying `production/backlog.yaml`.

**Additional gaps observed (written instructions only):**

- The skill specifies the `[A] / [E] / [N]` prompt in Phase 2 but provides no written instruction for what happens when the user chooses `[E]` (edit assignments). The edit path is unspecified — behavior after selecting `[E]` is undefined in the file.
- Phase 3 velocity computation caps rolling average at 5 sprints but does not specify how to handle sprint files where story completion count or estimate_days fields are missing or malformed.
- The `view` mode does not specify behavior when `production/roadmap.yaml` is missing — no stop message or fallback is written.
- `roadmap.yaml` schema shows `epic_status: not-started` as the default value but the skill does not instruct what value to write when an epic directory exists but its EPIC.md has no parseable `Status:` field.
- The `unassigned:` block in roadmap.yaml includes a `note` field but there is no written instruction for how the note is populated or whether it is user-authored vs. generated.