# Skill Spec: /sprint-close

> **Category**: sprint
> **Priority**: critical
> **Spec written**: 2026-06-11

## Skill Summary

`/sprint-close` orchestrates the full sprint close-out sequence by invoking five sub-skills in strict order: `/milestone-review`, `/smoke-check sprint`, `/team-qa sprint`, `/retrospective`, and `/gate-check`. It takes no argument. For each of steps 1–4 it displays a progress header, asks confirmation before running, surfaces BLOCKED output with optional Sonnet analysis, appends a step summary to a draft file in `production/session-state/drafts/`, and pauses for user approval before proceeding. Step 5 (`/gate-check`) applies a special override that first globs for an existing gate-check report and offers skip/re-run/abort options. After all five steps, it asks permission to write a structured close-out report to `production/sprint-close/sprint-close-N-YYYYMMDD.md`, silently syncs `production/backlog.yaml` story statuses, and displays a CLOSED declaration with recommended next steps (`/checkpoint`, then `/sprint-plan new` in a fresh session). The skill does not include `/sprint-plan new` itself.

---

## Static Assertions

These should pass before any behavioral testing:

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (Phase 0, Phase 1–5, Phase 6, Phase 7)
- [x] At least one verdict keyword present (`COMPLETE` appears in Phase 7 close declaration)
- [x] If `allowed-tools` includes Write/Edit: `"May I write"` language present (Phase 6: "May I write the close-out report to...")
- [x] Next-step handoff section present at end (Phase 7 displays `/checkpoint` and `/sprint-plan new` as next steps)

---

## Director Gate Checks

- **N/A**: `/sprint-close` does not directly trigger a PR-SPRINT or PR-MILESTONE director gate. It delegates to `/gate-check` (Step 5) which may trigger its own gates internally, but `/sprint-close` itself does not contain gate invocation logic. The skill's own confirmation prompts are user-confirmation gates, not director gate reviews.

---

## Test Cases

### Case 1: Happy Path — Full sequence completes with no blockers

**Fixture**:
- `production/sprint-status.yaml` exists with `sprint: 3`
- All five sub-skills (`milestone-review`, `smoke-check`, `team-qa`, `retrospective`, `gate-check`) return cleanly with no BLOCKED output
- No existing gate-check report in `production/gate-checks/`
- User answers Y to all confirmation prompts
- User answers Y to the Phase 6 write prompt

**Expected behavior**:
1. Phase 0: Reads `production/sprint-status.yaml`, extracts `sprint: 3`
2. Displays "Step 1 / 5: /milestone-review" header, asks "[Y] Run / [N] Abort"
3. Runs `Skill("milestone-review")`, displays 1–3 line summary
4. Asks "May I record this summary and continue to `/smoke-check`?" — user says Y
5. Appends step 1 result to `production/session-state/drafts/sprint-close-3-YYYYMMDD.md`
6. Repeats Gate-and-Record cycle for steps 2, 3, 4 (smoke-check, team-qa, retrospective)
7. Displays "Step 5 / 5: /gate-check" header; globs `production/gate-checks/gate-check-*.md`; finds none; runs Gate-and-Record cycle for gate-check
8. Phase 6: Asks "May I write the close-out report to `production/sprint-close/sprint-close-3-YYYYMMDD.md`?" — user says Y; writes structured report
9. Phase 7: Silently syncs `production/backlog.yaml` (done → done, not-done → carried-over); displays CLOSED box with `Sprint #3: CLOSED`, lists `/checkpoint` and `/sprint-plan new` as next steps; outputs `Verdict: COMPLETE`

**Assertions**:
- [ ] Sprint number 3 extracted from `sprint-status.yaml` before any sub-skill runs
- [ ] Progress header format matches "── Sprint #N Close-Out ──..." for each step
- [ ] Each step preceded by "[Y] Run / [N] Abort" confirmation
- [ ] Draft file written incrementally to `production/session-state/drafts/sprint-close-3-YYYYMMDD.md` after each confirmed step
- [ ] Step 5 globs for existing gate-check report before running
- [ ] Phase 6 "May I write" prompt fires before writing final report
- [ ] Final report written to `production/sprint-close/sprint-close-3-YYYYMMDD.md` with all six sections (Milestone Review, Smoke Check, Team QA, Retrospective, Gate Check, Status)
- [ ] Status line reads "Sprint #3: CLOSED"
- [ ] Backlog sync runs silently (no confirmation prompt)
- [ ] Close declaration shows `/checkpoint` and `/sprint-plan new` as next steps
- [ ] `Verdict: COMPLETE` displayed

**Case Verdict**: PASS

---

### Case 2: Blocked — `sprint-status.yaml` missing

**Fixture**:
- `production/sprint-status.yaml` does not exist

**Expected behavior**:
1. Phase 0: Attempts to read `production/sprint-status.yaml`; file not found
2. Outputs: "Cannot determine sprint number. Verify `production/sprint-status.yaml` exists."
3. Stops — no sub-skills invoked, no draft created, no prompts shown

**Assertions**:
- [ ] Skill does not proceed past Phase 0 when `sprint-status.yaml` is missing
- [ ] Error message matches the exact wording from Phase 0: "Cannot determine sprint number. Verify `production/sprint-status.yaml` exists."
- [ ] No sub-skills are invoked
- [ ] No draft file is created
- [ ] No confirmation prompts are shown

**Case Verdict**: PASS

---

### Case 3: Mode Variant — User aborts at step 2 confirmation

**Fixture**:
- `production/sprint-status.yaml` exists with `sprint: 5`
- Step 1 (`milestone-review`) completes successfully; user confirms "Y" to record and continue
- At step 2 confirmation ("[Y] Run / [N] Abort"), user answers N

**Expected behavior**:
1. Phase 0: Sprint number 5 extracted
2. Step 1 runs and completes; user confirms Y; draft appended
3. Step 2 header displayed; user answers N to "[Y] Run / [N] Abort"
4. Skill outputs: "Close-out paused. Run `/sprint-close` again to resume or continue steps manually."
5. Stops — steps 3, 4, 5 not run; no further prompts

**Assertions**:
- [ ] Skill halts immediately when user answers N at a before-run confirmation
- [ ] Pause message matches the verbatim text: "Close-out paused. Run `/sprint-close` again to resume or continue steps manually."
- [ ] Draft file from step 1 persists on disk (was already written before the abort)
- [ ] No sub-skills beyond step 1 are invoked
- [ ] No Phase 6 write prompt appears

**Case Verdict**: PASS

---

### Case 4: Edge Case — BLOCKED detected in a step's output, user declines Sonnet analysis and chooses to continue

**Fixture**:
- `production/sprint-status.yaml` exists with `sprint: 2`
- Step 1 (`milestone-review`) runs and returns output containing the word "BLOCKED"
- User answers N to "Blocker detected. Allow Sonnet-level analysis to help resolve it? [Y/N]"
- User answers "Continue anyway (note blocker in report)"
- User answers Y to "May I record this summary and continue..."
- All remaining steps run cleanly; user confirms all subsequent prompts

**Expected behavior**:
1. Phase 0: Sprint number 2 extracted
2. Step 1 runs; BLOCKED detected in output
3. Skill surfaces the blocker message verbatim
4. Asks "Blocker detected. Allow Sonnet-level analysis to help resolve it? [Y/N]" — user says N
5. Asks "Continue anyway (note blocker in report) or abort?" — user selects continue
6. Asks "May I record this summary and continue to `/smoke-check`?" — user says Y
7. Draft appended; sequence continues through steps 2–5 normally
8. Phase 6 and 7 execute normally; close-out report written; CLOSED declaration shown

**Assertions**:
- [ ] BLOCKED keyword in sub-skill output triggers the blocker prompt (not silently ignored)
- [ ] Blocker message surfaced verbatim before the Y/N prompt
- [ ] When user declines Sonnet analysis, no `Agent` with `model: "sonnet"` is spawned
- [ ] "Continue anyway or abort?" prompt is presented
- [ ] Sequence resumes normally after user selects continue
- [ ] Draft file is written even when a blocker was noted
- [ ] Final report still written upon Phase 6 approval

**Case Verdict**: PASS

---

### Case 5: Edge Case — Existing gate-check report found; user selects Skip

**Fixture**:
- `production/sprint-status.yaml` exists with `sprint: 7`
- Steps 1–4 complete cleanly with user confirming all prompts
- `production/gate-checks/gate-check-2026-06-10.md` exists containing:
  - A `## Verdict` line with `PASS`
  - Two lines matching `CONCERN`
  - No lines matching `FAIL`, `BLOCKED`, or `❌`

**Expected behavior**:
1. Steps 1–4 complete via Gate-and-Record cycle
2. Step 5 header displayed; skill globs `production/gate-checks/gate-check-*.md`
3. Finds `gate-check-2026-06-10.md`; reads it; extracts verdict (PASS), date (2026-06-10), failing items (none), concern items (2 items)
4. Displays the structured summary block showing filename, Verdict: PASS, Date, "Still failing: None", "Concerns: [2 items]"
5. Asks "[A] Skip — use existing report / [B] Run `/gate-check` fresh / [C] Abort close-out"
6. User selects A
7. Existing report path recorded in draft; proceeds to Phase 6
8. Phase 6 write prompt fires; user approves; report written with gate-check section noting existing report was used
9. Phase 7 executes; CLOSED declaration shown

**Assertions**:
- [ ] Skill globs for existing gate-check report before asking to run `/gate-check`
- [ ] Existing report's verdict, date, failing items, and concerns extracted and displayed
- [ ] "Still failing: None" displayed when no FAIL/BLOCKED/❌ lines found
- [ ] Concern items listed (capped at 10 per group)
- [ ] Three-option prompt (A/B/C) presented
- [ ] When user selects A: no `/gate-check` sub-skill is invoked
- [ ] Existing report path recorded in draft
- [ ] Phase 6 and Phase 7 proceed normally
- [ ] `/sprint-plan new` is listed in the next-steps output but NOT invoked by the skill itself

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Uses `"May I write"` before any file writes (Phase 6 uses this exact language before writing the close-out report; incremental draft appends also go through "May I record this summary and continue" approval)
- [x] Presents findings/draft to user before requesting approval (each step: 1–3 line summary shown before "May I record..." prompt; gate-check summary block shown before A/B/C prompt)
- [x] Ends with a recommended next step or follow-up action (Phase 7 close declaration lists `/checkpoint` then `/sprint-plan new`)
- [x] Does not auto-create files without user approval (exception: backlog sync in Phase 7 is explicitly documented as automatic and no-confirmation — this is intentional by the skill's design, not a compliance gap)

---

## Coverage Notes

**SP1 — Reads sprint/milestone state**: Satisfied. Phase 0 reads `production/sprint-status.yaml`. The skill does not directly read `production/milestones/` — milestone data is delegated to the `/milestone-review` sub-skill.

**SP2 — Correct sprint gate**: Not applicable. `/sprint-close` is an orchestrator and does not itself trigger PR-SPRINT or PR-MILESTONE director gates. Those gates live inside `/gate-check`, which this skill delegates to.

**SP3 — Structured output**: Partially satisfied. The close-out report (Phase 6) uses a consistent six-section format. The in-session progress display uses a consistent header format. The gate-check summary display (Step 5 Override) uses a defined structured block. Free-prose sections (1–3 line summaries) are bounded but not rigidly structured.

**SP4 — No auto-commit**: Satisfied for the report write. Gap: Phase 7 backlog sync (Write to `production/backlog.yaml`) is explicitly designed to run without confirmation — this is an intentional deviation from SP4 documented in the skill itself ("No confirmation needed — this is automatic on sprint close"). Testers should verify this behavior is acceptable for the project's write-protection requirements.

**Untested gaps**:
- Resume behavior: The skill says "Run `/sprint-close` again to resume" when paused, but the skill has no explicit resume-from-step logic (no state file tracking which steps are done). A user re-running the skill after a mid-sequence abort will restart from Step 1. This gap is not covered by any test case.
- User selects B (re-run gate-check fresh) in Step 5 Override — not independently tested; covered implicitly by Case 1's no-existing-report path.
- User selects C (abort) in Step 5 Override — not tested.
- BLOCKED handling when user selects Y for Sonnet analysis — Case 4 tests the N path only.
- Draft file naming collision if `/sprint-close` is run twice on the same date — behavior undefined by the skill.
- `production/backlog.yaml` missing when Phase 7 runs — skill says "If `production/backlog.yaml` exists" so it should silently skip, but this is not tested.
- The skill is assigned `model: haiku` in frontmatter, but the BLOCKED path spawns a `model: sonnet` agent. The interaction between the haiku-model orchestrator and the sonnet sub-agent is not tested for correctness or cost implications.