# Skill Spec: /player-segmentation
> **Category**: analytics
> **Priority**: medium
> **Spec written**: 2026-06-11

## Skill Summary

`/player-segmentation` defines player cohorts with behavioral thresholds and live ops lever mappings, producing `docs/analytics/player-segments.md`. The skill detects whether a segmentation document already exists (update vs. create mode), confirms data availability to determine whether thresholds are empirical or estimated, gathers the segmentation goal, then delegates segment design to a `growth-analyst` subagent using context extracted from the game concept, analytics plan, and live-ops strategy. The user reviews segments before the skill requests write approval, then outputs a summary with next-step skill recommendations.

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools` all present
- [x] 2+ phase headings — 8 phases present (Phase 1 through Phase 8)
- [x] Verdict keyword present — "Verdict: COMPLETE" in Phase 8 summary block
- [x] If Write/Edit in allowed-tools: "May I write" language present — Write is in allowed-tools; Phase 7 contains explicit "May I write the player segmentation to `docs/analytics/player-segments.md`?"
- [x] Next-step handoff present — Phase 8 lists four numbered next steps including `/retention-analysis` and `/ab-test`

---

## Director Gate Checks

N/A — the skill does not invoke any director-tier review agents. It spawns `growth-analyst` as an implementation subagent, not a director gate.

---

## Test Cases

### Case 1: Happy Path — Pre-launch, Retention Goal, No Prior Document

**Fixture**
- `design/gdd/game-concept.md` exists with title, genre, core loop, monetization model, target audience
- `docs/analytics/analytics-plan.md` exists with event taxonomy
- `docs/analytics/player-segments.md` does not exist
- `production/publishing/live-ops-strategy.md` exists

**Expected behavior**
- Phase 1 reads all four files without error
- Phase 2 is skipped (no existing document)
- Phase 3 prompts for data availability; user selects `No — pre-launch design`
- Phase 4 prompts for goal; user selects `Retention targeting`
- Phase 5 extracts event list from analytics plan, spawns `growth-analyst` with correct substitutions; agent returns 3–7 segments with thresholds marked `[ESTIMATE — calibrate post-launch]` and a calibration checklist
- Phase 6 presents segments; user selects `Accept all segments`
- Phase 7 asks "May I write...?"; user confirms
- Phase 7 writes `docs/analytics/player-segments.md` with Status `Draft — pre-launch`, calibration checklist section present
- Phase 8 outputs summary with `Verdict: COMPLETE`

**Assertions**
- AL1: Skill reads game-concept.md and analytics-plan.md before any segment content is produced
- AL2: Thresholds are sourced from analytics plan events or explicitly marked `[ESTIMATE]` — skill never invents thresholds silently
- AL3: Output document contains structured tables (Segment Transition Map, Live Ops Lever Mapping, Measurement)
- AL4: Write is gated behind explicit "May I write" confirmation in Phase 7
- AL5: Phase 8 recommends `/retention-analysis` and `/ab-test` as follow-on skills

**Verdict**: COMPLETE

---

### Case 2: Failure / Blocked — No Game Concept

**Fixture**
- `design/gdd/game-concept.md` does not exist
- All other files absent or irrelevant

**Expected behavior**
- Phase 1 attempts to read game-concept.md, finds it absent
- Skill halts immediately with message: "No game concept found. Run `/brainstorm` first."
- No questions are asked, no subagent is spawned, no file is written

**Assertions**
- Skill outputs the exact stop message specified in Phase 1
- No `AskUserQuestion` calls are made after the stop condition
- No Task call is made to `growth-analyst`
- `docs/analytics/player-segments.md` is not created

**Verdict**: BLOCKED

---

### Case 3: Mode Variant — Existing Document, Update Mode

**Fixture**
- `design/gdd/game-concept.md` exists
- `docs/analytics/analytics-plan.md` exists
- `docs/analytics/player-segments.md` already exists with prior segments

**Expected behavior**
- Phase 1 loads the existing player-segments.md
- Phase 2 detects the document exists; presents `AskUserQuestion` with three options: "Review and update existing segments", "Add new segments", "Start fresh"
- User selects `Review and update existing segments`
- Phases 3–6 proceed normally, informed by existing document content
- Phase 7 asks "May I write...?" before overwriting
- Final document reflects updates; Status updated appropriately

**Assertions**
- Phase 2 branch is entered when existing document is detected
- User is not silently overwritten — AskUserQuestion is issued
- "May I write" gate is still required even for updates
- AL4: Write gate is not bypassed because a prior document exists

**Verdict**: COMPLETE (update mode)

---

### Case 4: Edge Case — No Analytics Plan Exists

**Fixture**
- `design/gdd/game-concept.md` exists
- `docs/analytics/analytics-plan.md` does not exist
- `docs/analytics/player-segments.md` does not exist
- `production/publishing/live-ops-strategy.md` does not exist

**Expected behavior**
- Phase 1 reads game-concept.md successfully; notes analytics-plan.md and live-ops-strategy.md are absent (does not stop — only missing game concept is a stop condition)
- Phase 5 notes available signals as "unknown — design placeholder thresholds" per the explicit fallback instruction
- `growth-analyst` prompt substitutes `[EVENT LIST FROM ANALYTICS PLAN, or "not yet defined"]` with "not yet defined"
- Agent produces segments with all thresholds marked `[ESTIMATE — calibrate post-launch]`
- Calibration checklist includes item: "Check that signal events are being tracked before activating any live ops lever"
- Skill completes normally through Phase 8

**Assertions**
- Skill does not halt when analytics-plan.md is absent (only game-concept.md absence triggers stop)
- AL1: Skill does not invent event names — substitutes "not yet defined" per Phase 5 fallback
- AL2: No benchmarks are fabricated; all thresholds marked as estimates
- Output document is Status `Draft — pre-launch` with calibration checklist present
- Phase 8 still recommends checking analytics-plan.md as next step

**Verdict**: COMPLETE (degraded — placeholder thresholds)

---

### Case 5: Most Relevant Variant — Live Data Available, Monetization Goal, Threshold Revision Loop

**Fixture**
- All source files exist with rich data
- `docs/analytics/player-segments.md` does not exist
- Phase 3: user selects `Yes — live data available`
- Phase 4: user selects `Monetization optimization`
- Phase 6: user selects `Revise thresholds` (triggers adjustment loop)

**Expected behavior**
- Phase 3 records `Yes — live data available`; output document will be marked Status `Active — calibrated on live data`
- Phase 5 spawns `growth-analyst` with `Data availability: Yes — live data available`; agent produces thresholds without `[ESTIMATE]` markers and without a calibration checklist
- Segments are monetization-focused (e.g., high-spend potential, low-spend, lapsed spenders)
- Phase 6 presents segments; user selects `Revise thresholds`; skill handles adjustment inline and returns to the Phase 6 prompt
- After revision, user selects `Accept all segments`
- Phase 7 asks "May I write...?"; user confirms
- Written document has Status `Active — calibrated on live data`; no calibration checklist section (or checklist is empty/omitted for live-data mode)
- Phase 8 summary shows `Status: Active`

**Assertions**
- AL1: Thresholds sourced from live data signals in analytics-plan.md — not invented
- AL2: Expected playerbase % estimates include confidence levels (High/Medium/Low) per agent prompt spec
- AL3: All four structured tables present in output document
- AL4: Write gate in Phase 7 is not bypassed after the revision loop
- Revision loop (`Revise thresholds` → inline adjustment → return to prompt) terminates when user accepts
- Segment count stays within 3–7 per the Collaborative Protocol constraint
- AL5: `/ab-test` recommended in Phase 8 for lever effectiveness testing

**Verdict**: COMPLETE (live-data, monetization mode)

---

## Protocol Compliance

- [x] "May I write" before file writes — Phase 7 contains the explicit ask before Write is called
- [x] Presents findings before approval — Phase 5 presents segments to user for review before Phase 6 approval; Phase 6 review precedes Phase 7 write ask
- [x] Ends with next step — Phase 8 lists four explicit next steps with skill names
- [x] No auto-create without approval — Collaborative Protocol section explicitly states "Never write files without asking"

---

## Coverage Notes

**AL1** (reads data before analysis, never invents numbers): Covered by Cases 1, 4, 5. Phase 1 mandates reading game-concept.md and analytics-plan.md before any segment work begins. Phase 5 explicitly handles the no-analytics-plan case with a "not yet defined" placeholder rather than inventing events. Case 4 specifically targets this fallback path.

**AL2** (benchmarks explicitly sourced): Covered by Cases 1 and 5. Phase 3 data-availability question determines whether thresholds are empirical (live data) or explicitly marked as estimates. The agent prompt requires confidence levels on playerbase % estimates. Case 2 (blocked) is not an AL2 test since no data reaches the agent.

**AL3** (structured findings table with severity): Covered by Cases 1 and 5. The Phase 7 document template mandates four named tables: Segments, Segment Transition Map, Live Ops Lever Mapping, and Measurement. Severity is not a direct field in this skill's domain — the analog is confidence level on thresholds and the Health Signal column in the transition map.

**AL4** (output gated behind "May I write"): Covered by all write-path cases (Cases 1, 3, 5). Case 3 specifically verifies the gate is not bypassed during an update. The Collaborative Protocol section reinforces this with an explicit rule.

**AL5** (explicit follow-on skill recommended): Covered by Cases 1 and 5. Phase 8 names `/retention-analysis` and `/ab-test` by name as follow-on skills. Case 2 (blocked) intentionally omits next steps since the skill halts before producing output.

**Gap — Director Gate**: Not applicable. The skill's only subagent is `growth-analyst`, an implementation specialist. No director-tier agent is invoked. Case 5 was assigned to the most distinctive runtime variant (live-data + revision loop) rather than a non-existent director gate.