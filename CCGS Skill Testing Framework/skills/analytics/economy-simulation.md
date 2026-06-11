# Skill Spec: /economy-simulation

> **Category**: analytics
> **Priority**: high
> **Spec written**: 2026-06-11

## Skill Summary

`/economy-simulation` is a model-based economy projection skill that works exclusively from the economy GDD math model — it never runs game code. It reads economy-related GDDs, prompts the user to select a scope and scenario (baseline/hardcore/casual/multiple/specific-concern), spawns a `growth-analyst` subagent to perform arithmetic projections over 30/60/90-day windows, then presents findings before gating the report write behind explicit user approval. Output is a structured markdown report at `docs/analytics/economy-sim-[slug].md` covering resource flow tables, time-to-progression estimates, inflation risk classification (INFLATIONARY / DEFLATIONARY / BALANCED / VOLATILE), sink/faucet balance, a severity-ranked design concerns table, and a full assumptions log. The skill is explicitly distinct from `/balance-check` (formula correctness) and `/balance-sim` (combat AI simulation).

---

## Static Assertions
- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (8 phases present: Phase 1–8)
- [ ] At least one verdict keyword present (`Verdict: COMPLETE` in Phase 8 summary block)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present (Phase 7: "May I write the economy simulation to `docs/analytics/economy-sim-[slug].md`?")
- [ ] Next-step handoff section present at end (Phase 8 `Next steps:` block lists 4 explicit follow-on actions including `/balance-check`, `/ab-test`, and re-run of `/economy-simulation`)

---

## Director Gate Checks
- **Full mode**: N/A — skill contains no director gate logic
- **Lean mode**: N/A
- **Solo mode**: N/A
- **N/A**: This skill has no director gate review phase. It escalates BLOCKING concerns to `economy-designer` (Phase 6, "Flag for economy-designer" option) but this is a delegation note in the report, not a gate verdict.

---

## Test Cases

### Case 1: Happy Path — Baseline Player Currency Simulation

**Fixture**
- `design/gdd/currency-system.md` exists with complete math model: resource names, earn rates per session, sink costs, progression gates, design-intent pacing
- `design/gdd/game-concept.md` exists with game title, genre, and monetization model
- `docs/analytics/analytics-plan.md` exists (provides real data context)
- No ADRs reference economy

**Expected behavior**
1. Phase 1 lists the currency GDD found; presents it to user
2. Phase 2 offers the GDD as a selectable option; user selects it
3. Phase 3 user selects `Baseline player`
4. Phase 4 extracts resources, source rates, sink rates, bottlenecks, and formulas from the GDD; no undefined variables flagged
5. Phase 5 spawns `growth-analyst` Task with correct context; agent returns Day 7/14/30/60/90 resource flow table, time-to-progression table, inflation risk = BALANCED, sink/faucet analysis, no BLOCKING concerns, empty or minimal assumptions log, confidence = HIGH
6. Phase 5 presents projection results to user before writing
7. Phase 6 user selects `Write report as-is`
8. Phase 7 asks "May I write the economy simulation to `docs/analytics/economy-sim-currency-2026-06-11.md`?"; user approves; file written
9. Phase 8 outputs the summary block with Verdict: COMPLETE

**Assertions**
- Phase 1 output names GDD files found before any AskUserQuestion
- Phase 4 extracts all 6 categories (resource types, source rates, sink rates, bottlenecks, formulas, design intent)
- Phase 5 Task prompt includes all 6 template variables (GAME TITLE, GENRE, SYSTEM, SCENARIOS, MONETIZATION MODEL, math model paste)
- Projection presented to user prior to any Write call
- "May I write" question appears before Write tool is used
- Output file path matches `docs/analytics/economy-sim-[slug].md` pattern
- Phase 8 summary block includes: Scenarios, Risk, Concerns count, Confidence, Output path, 4 next steps

**Case Verdict**: PASS if all 7 assertion points are satisfied with no file writes before explicit approval

---

### Case 2: Failure / Blocked — Incomplete GDD Math Model

**Fixture**
- `design/gdd/crafting-economy.md` exists but references formula variable `base_drop_rate` without defining its value
- No `docs/analytics/analytics-plan.md`
- No ADRs

**Expected behavior**
1. Phase 4 detects undefined variable `base_drop_rate`
2. Phase 4 emits explicit flag block: "The GDD references [base_drop_rate] but does not define its value. Simulation will use [assumed value] — flag this assumption in the output."
3. Phase 5 `growth-analyst` Task prompt includes the assumption in context
4. Agent's Assumptions Log section lists `base_drop_rate` with assumed value and rationale
5. Agent sets Confidence Level to MEDIUM or LOW (due to assumption count)
6. Phase 8 summary reflects degraded confidence level

**Assertions**
- Undefined variable produces an explicit inline flag in Phase 4 output (not silently skipped)
- Assumption appears in Assumptions Log table in the written report
- Confidence is not HIGH when assumptions are present
- Skill does not block/abort — it proceeds with flagged assumptions

**Case Verdict**: PASS if assumption is surfaced, logged, and confidence is appropriately downgraded; FAIL if assumption is silent

---

### Case 3: Mode Variant — Multiple Scenarios (All Three Player Types)

**Fixture**
- Economy GDD with complete math model
- `game-concept.md` present

**Expected behavior**
1. Phase 3 user selects `Multiple scenarios` — Run all three and compare
2. Phase 5 Task prompt lists all three scenarios (Baseline, Hardcore, Casual)
3. Agent produces three separate Resource Flow Projection sections (one per scenario)
4. Agent produces a Time-to-Progression table with three scenario columns
5. Phase 5 presents combined results before write
6. Phase 7 report Simulation Summary table has one row per scenario (3 rows)
7. Design Concerns table identifies which player scenario each concern affects most

**Assertions**
- Task prompt contains all three scenario labels
- Report contains 3 rows in the Simulation Summary table
- Time-to-Progression table has columns for all 3 scenarios plus Design Intent and Status
- Each concern row in Design Concerns identifies affected scenario
- Single "May I write" gate covers the combined report (not one per scenario)

**Case Verdict**: PASS if all three scenarios are projected and the combined report structure is correct

---

### Case 4: Edge Case — Custom Scope with Specific Concern

**Fixture**
- Phase 1 finds no economy-related GDDs in `design/gdd/`
- User selects `Custom scope` in Phase 2 and describes: premium currency, earn via daily login, sink via cosmetic shop, concern: "premium currency inflating over 30 days with no sink scaling"
- Phase 3 user selects `Specific concern`

**Expected behavior**
1. Phase 1 presents an empty or non-economy GDD list; does not abort
2. Phase 2 AskUserQuestion includes `Custom scope` option; user selects it
3. Skill asks follow-up questions: resources (names and types), primary sources, primary sinks, design intent
4. Phase 3 AskUserQuestion includes `Specific concern` option; user selects it; skill asks for one-sentence description
5. Phase 5 Task prompt populates `Concern (if specific)` field with the user's stated concern
6. Agent's Inflation Risk section specifically addresses the inflation concern
7. Assumptions Log is populated (since no GDD provided the math model — all values came from user description)
8. Confidence is likely LOW due to no GDD source

**Assertions**
- Skill does not abort when no economy GDDs are found
- Custom scope triggers follow-up questions for resources/sources/sinks/intent before Phase 3
- Specific concern populates the `Concern` field in the Phase 5 Task prompt (not left as "none")
- Assumptions Log has entries (user-provided values are still assumptions without a GDD source)
- Inflation risk classification directly addresses the stated concern

**Case Verdict**: PASS if custom scope path collects required inputs and concern is addressed in analysis; FAIL if skill requires a GDD to proceed

---

### Case 5: Follow-on Scenario — Re-run After GDD Revision ("Design a Follow-up Scenario")

**Fixture**
- Initial simulation has been run; Phase 5 results showed INFLATIONARY risk with one BLOCKING concern
- Phase 6 user selects `Design a follow-up scenario`

**Expected behavior**
1. Phase 6 detects "Design a follow-up scenario" selection
2. Skill asks user to describe adjusted parameters (e.g., "reduce earn rate by 20%, add daily soft cap")
3. Skill adjusts parameters inline without returning to Phase 2/3 for full re-scope
4. Phase 5 is re-run with new parameters; `growth-analyst` Task is spawned again
5. New results presented to user
6. Phase 6 is re-entered for the follow-up results
7. When user selects `Write report as-is` (or another write option), Phase 7 asks "May I write" again
8. Output slug reflects the re-run date or a distinguishing label

**Assertions**
- "Design a follow-up scenario" triggers inline parameter adjustment + Phase 5 re-run (not a full restart from Phase 1)
- Second Task spawned with updated parameters visible in the prompt
- "May I write" gate is required again for the follow-up report (not auto-written)
- Follow-up report is written to a distinct slug (not overwriting the first report)

**Case Verdict**: PASS if Phase 5 re-run occurs with adjusted parameters and write gate is preserved; FAIL if skill auto-writes or returns to Phase 1 unnecessarily

---

## Protocol Compliance
- [ ] Uses "May I write" before any file writes — Phase 7 explicitly states: "Ask: 'May I write the economy simulation to `docs/analytics/economy-sim-[slug].md`?'" and "Wait for confirmation"
- [ ] Presents findings/draft before requesting approval — Phase 5 ends with "Present projection results to user before writing"; Phase 6 reviews results before write decision
- [ ] Ends with recommended next step — Phase 8 lists 4 explicit next steps: fix top concern, run `/balance-check` if BLOCKING, run `/ab-test` post-ship, re-run `/economy-simulation` after GDD revisions
- [ ] Does not auto-create files without approval — Collaborative Protocol section explicitly states "Never write files without asking"

---

## Coverage Notes

**AL1 — Data-before-analysis**: MET. Phase 1 reads GDDs, analytics plan, ADRs, and game-concept.md before any projection. Phase 4 reads the selected GDD in full before Phase 5 runs the agent.

**AL2 — Benchmark sourcing**: PARTIAL. The skill does not explicitly state sources for benchmarks used in the projection. The `growth-analyst` Task prompt instructs the agent to "compare to design intent (if stated in GDD)" for progression pacing, but does not require the agent to cite external benchmarks or state the source of any industry comparison values it may use. If the agent produces inflation risk assessments drawing on implicit knowledge (e.g., "typical F2P earn/spend ratios"), those sources are not required to be logged. The Assumptions Log captures assumed GDD values but not benchmark origins.

**AL3 — Structured findings**: MET. Phase 5 agent output is fully structured: Resource Flow Summary is tabular (Day/Resource/Earned/Spent/Net/Stockpile), Time-to-Progression is tabular, Design Concerns table includes Severity column enabling priority ordering (BLOCKING first).

**AL4 — May-I-write before report**: MET. Phase 7 gates the write behind an explicit "May I write" question with "Wait for confirmation" instruction.

**AL5 — Follow-on handoff**: MET. Phase 8 next steps explicitly name `/balance-check`, `/ab-test`, and `/economy-simulation` (re-run) as follow-on skills with conditions for each.

**Missing phases / gaps**:
- No phase explicitly handles the case where `design/gdd/` directory does not exist at all (Phase 1 would return empty results; skill's behavior is inferred from Phase 2 "Custom scope" option but not stated)
- Phase 5 instructs "Spawn the `growth-analyst` agent via Task" but the skill's frontmatter lists `Task` in `allowed-tools` — the agent name `growth-analyst` is not defined elsewhere in the framework; if no such agent exists, the Task call may fall back to a generic subagent
- "Flag for economy-designer" option in Phase 6 adds a delegation task but the skill does not specify where this task is written or to which file
- The Collaborative Protocol note "BLOCKING concerns must be surfaced immediately; do not bury them in a long report" is guidance to the agent but there is no phase that gates on BLOCKING concerns before proceeding to write (the write gate is approval-based, not severity-based)
- No explicit handling for the case where the user declines the "May I write" prompt in Phase 7 (skill ends at the gate without a stated fallback or re-offer path)