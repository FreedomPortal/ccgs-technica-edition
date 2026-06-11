# Skill Spec: /export-status
> **Category**: sprint
> **Priority**: medium
> **Spec written**: 2026-06-11

## Skill Summary

`/export-status` generates a production status report from sprint history, backlog state, and milestone definitions. It computes velocity (3- and 5-sprint rolling averages), a predictability score (must-have completion rate), scope creep rate (mid-sprint additions ratio), and a completion horizon range per milestone. The skill supports three output modes — `full`, `lean`, and `metrics` — defaulting to `full` when no argument is given. Output is written to `production/reports/status-YYYY-MM-DD.md` after explicit user approval, and a lean summary is always printed to chat after writing regardless of mode.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model`)
- [x] 2+ phase headings found (Phase 1, Phase 2, Phase 3, Phase 4)
- [x] At least one verdict keyword present ("Verdict: COMPLETE — status report written.")
- [x] If allowed-tools includes Write/Edit: "May I write" language present (Phase 4: "Ask: 'May I write `production/reports/status-[date].md`? [Y/N]'")
- [x] Next-step handoff section present ("Recommended Next Steps" section with `/milestone-review`, `/roadmap update`, `/sprint-plan`)

---

## Director Gate Checks

**N/A** — The skill contains no director review invocation, no PR-SPRINT or PR-MILESTONE gate, and no subagent spawning for review. It is a read-compute-write pipeline with a single user approval gate.

---

## Test Cases

### Case 1: Happy Path — Full Mode with Complete Data

**Fixture:**
- `production/sprints/sprint-01.md` through `sprint-05.md`, each with planned stories, completed stories, must-have counts, and mid-sprint additions
- `production/backlog.yaml` with stories grouped by status and milestone_target
- `production/sprint-status.yaml` with current sprint number and blocked stories
- `production/milestones/active.txt` containing a milestone name
- `production/milestones/definitions/[name].md` with Exit Criteria section

**Invocation:** `/export-status full`

**Expected behavior:**
- Phase 1 loads all five input sources without error
- Phase 2 computes 3-sprint and 5-sprint velocity averages; confidence = HIGH (5 sprints, low std dev)
- Phase 2 produces predictability score, scope creep rate, and completion horizon with date range
- Phase 3 formats a full report with velocity table including Avg row, Predictability, Scope Creep, Milestone Progress (exit criteria checkboxes), Current Sprint Snapshot, and Blockers sections
- Phase 4 asks "May I write `production/reports/status-[date].md`? [Y/N]" before writing
- On approval, writes to `production/reports/`; creates directory if absent
- Prints lean summary to chat after write

**Assertions:**
- Report contains velocity table with all 5 sprint rows plus Avg row
- Confidence label is HIGH
- Predictability reported as `[avg]% ([min]%–[max]% range over last N sprints)`
- Scope creep reported as `[avg]% per sprint`
- Milestone section includes exit criteria checkboxes from definition file
- Lean summary printed to chat after write (regardless of mode selected)
- No file written before approval gate

**Verdict:** PASS if all assertions hold

---

### Case 2: Failure / Blocked — No Sprint Files and No Backlog

**Fixture:**
- `production/` directory exists but contains no `sprints/` subdirectory and no `backlog.yaml`
- `production/sprint-status.yaml` absent
- `production/milestones/active.txt` absent

**Invocation:** `/export-status full`

**Expected behavior:**
- Phase 1: sprint glob returns empty; all fields recorded as null; backlog section skipped; sprint-status.yaml absent noted; active milestone = "none set"
- Phase 2: all velocity/predictability/scope metrics = "No data"; horizon = "Cannot estimate — no velocity data"; confidence = LOW
- Phase 3: full report renders with graceful degradation values per the Graceful Degradation table (velocity = "No data", blockers = "(sprint-status.yaml not found)", exit criteria = "(No definition — run /milestone-define init [name])")
- Phase 4: approval gate still fires; on approval, writes partial report

**Assertions:**
- Skill does not hard-fail or abort — produces a partial report
- Report contains "No data" strings for velocity, predictability, and scope creep
- Completion horizon reads "Cannot estimate — no velocity data"
- Blockers section reads "(sprint-status.yaml not found)"
- "May I write" gate still appears before file write

**Verdict:** PASS if skill degrades gracefully and still reaches the write gate

---

### Case 3: Mode Variant — `metrics` Mode

**Fixture:**
- Same complete fixture as Case 1 (5 sprints, backlog, sprint-status, active milestone)

**Invocation:** `/export-status metrics`

**Expected behavior:**
- Phase 3 formats output as a YAML-like structured block only, no narrative text
- All 13 fields present: `velocity_avg_3sprint`, `velocity_avg_5sprint`, `velocity_confidence`, `estimate_days_avg`, `predictability_avg_pct`, `scope_creep_avg_pct`, `active_milestone`, `remaining_stories_active`, `remaining_days_active`, `horizon_lo`, `horizon_hi`, `blocked_count`, `report_date`
- Phase 4 writes to the same output path (`production/reports/status-[date].md`)
- Lean summary still printed to chat after write

**Assertions:**
- Output file contains no narrative sections (no `##` headings, no prose interpretation strings)
- All 13 metric keys present with non-empty values
- `horizon_lo` and `horizon_hi` are ISO date strings (YYYY-MM-DD)
- Lean summary printed to chat after write (spec explicitly states "regardless of mode")

**Verdict:** PASS if metrics block is complete and lean summary appears in chat

---

### Case 4: Edge Case — Exactly 2 Sprints, Partial Must-Have Data

**Fixture:**
- `production/sprints/sprint-01.md` — has must-have planned/completed fields
- `production/sprints/sprint-02.md` — must-have fields absent (null)
- `production/backlog.yaml` present with stories for one milestone
- No `sprint-status.yaml`

**Invocation:** `/export-status lean`

**Expected behavior:**
- Phase 1: sprint-02 must-have recorded as null, not 0; sprint is not skipped
- Phase 2: velocity confidence = LOW (fewer than 3 sprints); predictability average computed from sprint-01 only (sprint-02 excluded per spec: "exclude it from average — do not substitute 0"); scope creep: if only 1 sprint has addition counts, reports "Insufficient data" (spec requires fewer than 2 sprints with addition counts)
- Phase 3: lean mode output with confidence = LOW, predictability computed from 1 sprint, scope creep = "Insufficient data"
- Phase 4: approval gate fires normally

**Assertions:**
- Confidence is LOW, not MEDIUM
- Predictability is not calculated using 0 for the null sprint
- Scope creep reads "Insufficient data" (not a percentage)
- Sprint-02 appears in velocity history (not silently skipped)

**Verdict:** PASS if null data is handled without substitution and confidence is correctly LOW

---

### Case 5: Most Relevant Variant — `lean` Mode Default Fallback (No Argument Provided)

**Fixture:**
- 3 complete sprint files
- `production/backlog.yaml` present
- No `sprint-status.yaml`, no `active.txt`

**Invocation:** `/export-status` (no argument)

**Expected behavior:**
- Skill defaults to `full` mode (spec: "Default mode when no argument: `full`")
- Phase 3 renders full report format, not lean
- Active milestone shows "none set"; all milestones with remaining stories shown
- Blockers section reads "(sprint-status.yaml not found)"
- Confidence = MEDIUM (3 sprints; std dev / mean must be ≤ 40% to qualify — outcome depends on fixture data)
- Phase 4 approval gate fires; lean summary printed to chat after write

**Assertions:**
- Full report format is used, not lean
- Active milestone = "none set" (no active.txt)
- All milestones with remaining stories are listed
- Blockers = "(sprint-status.yaml not found)"
- "May I write" gate appears before file write

**Verdict:** PASS if `full` mode is applied by default and missing-optional-input strings match the Graceful Degradation table

---

## Protocol Compliance

- [x] "May I write" before file writes — Phase 4 explicitly: "Ask: 'May I write `production/reports/status-[date].md`? [Y/N]'"
- [x] Presents findings before approval — Phase 2 and Phase 3 compute and format the full report before Phase 4 fires the write gate
- [x] Ends with next step — "Recommended Next Steps" section lists `/milestone-review`, `/roadmap update`, `/sprint-plan`
- [x] No auto-create without approval — write only occurs on user approval in Phase 4; directory creation (`production/reports/`) is conditional on approval

---

## Coverage Notes

**SP1** — COVERED. Phase 1 explicitly globs `production/sprints/sprint-*.md` and reads `production/backlog.yaml`, `production/sprint-status.yaml`, `production/milestones/active.txt`, and milestone definition files before any output is produced.

**SP2** — NOT APPLICABLE (gap by design). The skill contains no PR-SPRINT or PR-MILESTONE director gate. There is no `full` vs. `lean/solo` mode distinction for gating — all modes share the same single user approval gate in Phase 4. No director review is invoked at any point. If a gate check was intended for the `full` mode path, it is not written into the skill.

**SP3** — COVERED for `metrics` and `lean` modes. The `full` mode output uses a defined table and section structure. The spec prescribes exact field names, labels, and format strings for all three modes, reducing free-prose variance. Partial gap: the "Notes" column in the velocity table and the blockers list are free-text fields, but this is a minor surface area.

**SP4** — COVERED. Phase 4 requires explicit "May I write ... [Y/N]" approval before writing `production/reports/status-[date].md`. The directory creation step is also gated behind that approval. The skill does not write to any sprint files.

**Additional gap — `production/stage.txt`**: The full mode report header references `Stage: [stage from production/stage.txt or "Unknown"]` but Phase 1 does not list `production/stage.txt` as an input to load. The skill does not specify what happens if the file is absent beyond the fallback string "Unknown". This input is undocumented in the Inputs section and the Graceful Degradation table — test cases should not assert specific behavior beyond the "Unknown" fallback string.