---
name: economy-simulation
description: "Model-based economy projection: resource flow analysis, time-to-progression estimates, inflation risk, and sink/faucet balance. Works from the economy GDD math model — does NOT run game code. Distinct from /balance-check (formula correctness) and /balance-sim (AI vs AI combat). Produces docs/analytics/economy-sim-[slug].md."
argument-hint: "[optional: economy system slug or scenario name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Disambiguation

This skill is distinct from two similar-sounding skills:

- **`/balance-check`** — verifies that economy formulas are mathematically correct and identifies outliers in static curves (e.g., XP table gaps, item pricing outliers)
- **`/balance-sim`** — runs AI-vs-AI combat simulation to find dominant strategies in the combat system
- **`/economy-simulation`** (this skill) — projects how the economy *evolves over time* given the math model: where does the resource stockpile go after 30/60/90 days? Is there inflation risk? Does time-to-progression match design intent?

If the user's question is "is my formula correct?", use `/balance-check`.
If the question is "which build wins in a fight?", use `/balance-sim`.
If the question is "will my economy be healthy 60 days after launch?", this is the right skill.

---

## Phase 1: Detect Current State

Read:
- `design/gdd/` — find economy-related GDDs: currency systems, progression curves, crafting economies, loot tables
- `docs/analytics/analytics-plan.md` — existing economy event tracking (provides real data context if available)
- `docs/architecture/adr-*.md` — any economy architecture decisions
- `design/gdd/game-concept.md` — game title, genre, monetization model

List the economy-related GDDs found. Present them to the user.

---

## Phase 2: Select Scope

Use `AskUserQuestion`:
- Prompt: "Which economy system do you want to simulate?"
- Options (auto-generated from GDDs found in Phase 1 — list up to 5; add "Custom" if needed):
  - [GDD-based options]
  - `Custom scope` — I'll describe the system to simulate

If "Custom scope", ask the user to describe:
- Resources involved (names and types: consumable / persistent / premium)
- Primary sources (how players earn)
- Primary sinks (how players spend)
- The design intent (what progression pace is desired)

---

## Phase 3: Define Simulation Scenario

Use `AskUserQuestion`:
- Prompt: "What scenario do you want to project?"
- Options:
  - `Baseline player` — Average player, no special behavior, follows main content path
  - `Hardcore player` — Sessions every day, completes all available activities
  - `Casual player` — 2–3 sessions per week, skips optional content
  - `Multiple scenarios` — Run all three and compare (recommended for launch validation)
  - `Specific concern` — I have a specific inflation or depletion concern to investigate

If "Specific concern", ask the user to describe the concern in one sentence.

---

## Phase 4: Read Economy GDD

Read the selected economy GDD(s) in full. Extract:
- All resource types (names, categories, whether they accumulate or expire)
- Source rates (how much is earned per session / per action / per day)
- Sink rates (cost of progressions, crafting, purchases)
- Bottlenecks by design (intentional gates — note separately from emergent bottlenecks)
- Any formula that governs earn/spend rates

If formulas use variables not defined in the GDD, flag them explicitly:
> "The GDD references [variable] but does not define its value. Simulation will
> use [assumed value] — flag this assumption in the output."

---

## Phase 5: Run Projection

Spawn the `growth-analyst` agent via Task with this prompt:

```
You are the growth-analyst for [GAME TITLE], a [GENRE] game.

Simulation scope: [SYSTEM FROM PHASE 2]
Scenario(s): [SCENARIOS FROM PHASE 3]
Concern (if specific): [CONCERN, or "none"]
Monetization model: [MODEL FROM game-concept.md]

Economy math model (extracted from GDD):
[PASTE: resources, sources, sinks, formulas, design intent, bottlenecks]

Simulate the economy over 30, 60, and 90 days for each requested scenario.
Do NOT run game code — work entirely from the math model. Use arithmetic projections.

For each scenario, produce:

1. Resource Flow Summary (tabular)
   | Day | Resource | Earned | Spent | Net | Stockpile |
   Calculate at Day 7, 14, 30, 60, 90.
   If the resource accumulates without a sink, the stockpile column will grow — flag this.

2. Time-to-Progression Estimates
   For each major progression gate identified in the GDD (level unlock, item craft, etc.):
   - Estimated days to reach the gate for this scenario
   - Compare to design intent (if stated in GDD)
   - Flag if faster than intended (devalues content) or slower than intended (frustration risk)

3. Inflation Risk Assessment
   - INFLATIONARY: sources > sinks — stockpile grows indefinitely (currency loses meaning)
   - DEFLATIONARY: sinks > sources — players run out before progression is complete (frustration)
   - BALANCED: reasonable earn/spend ratio with intended scarcity at gates
   - VOLATILE: rate ratio changes significantly across the 90-day window

4. Sink/Faucet Balance
   At each time window, calculate: total earned vs. total spent.
   Identify the primary drain (largest single sink) and flag if it dominates spending to
   the exclusion of other meaningful choices.

5. Design Concerns (flagged items)
   List each concern with:
   - Severity: BLOCKING (breaks the economy) / MODERATE (degrades experience) / MINOR
   - Which player scenario it affects most
   - Recommended adjustment: tweak earn rate by X%, add sink at Y gate, etc.

6. Assumptions Log
   List every value you assumed because the GDD did not specify it.
   Each assumption: [variable] assumed as [value] because [rationale].

7. Confidence Level
   Overall: HIGH / MEDIUM / LOW
   Based on: completeness of GDD math model, number of assumptions made,
   whether the model is self-consistent.
```

Present projection results to user before writing.

---

## Phase 6: Review and Prioritize

After presenting the projection, ask:

Use `AskUserQuestion`:
- Prompt: "How would you like to act on the simulation results?"
- Options:
  - `Write report as-is` — Document what was found; design decisions are separate
  - `Add fix recommendations` — Include specific tuning recommendations in the report
  - `Design a follow-up scenario` — I want to re-run with adjusted parameters
  - `Flag for economy-designer` — I want to escalate BLOCKING concerns for GDD revision

If "Design a follow-up scenario", adjust parameters inline and re-run Phase 5 before writing.

If "Flag for economy-designer", note this in the output and add a delegation task.

---

## Phase 7: Write Report

Ask: "May I write the economy simulation to `docs/analytics/economy-sim-[slug].md`?"
(slug = system name + date, e.g., `economy-sim-currency-2026-06-10`)

Wait for confirmation. Create `docs/analytics/` if needed.

```markdown
# Economy Simulation — [System Name]
**Simulated:** [date]
**Scope:** [economy system]
**Scenarios:** [list]
**Confidence:** [HIGH / MEDIUM / LOW]

---

## Simulation Summary

| Scenario | Inflation Risk | 30d Gate Pacing | 90d Stockpile Trend |
|----------|---------------|-----------------|---------------------|
[one row per scenario]

---

## Resource Flow Projections

### [Scenario Name]

| Day | [Resource] Earned | [Resource] Spent | Net | Stockpile |
|-----|-------------------|------------------|-----|-----------|
[7 / 14 / 30 / 60 / 90]

---

## Time-to-Progression

| Progression Gate | [Scenario A] Days | [Scenario B] Days | Design Intent | Status |
|-----------------|-------------------|-------------------|---------------|--------|
[from agent output]

---

## Inflation Risk: [INFLATIONARY / DEFLATIONARY / BALANCED / VOLATILE]

[1–2 paragraph explanation]

---

## Sink/Faucet Balance

[Analysis from agent output]

---

## Design Concerns

| Severity | Concern | Scenario | Recommendation |
|----------|---------|----------|----------------|
[BLOCKING items first]

---

## Assumptions Log

| Variable | Assumed Value | Rationale |
|----------|--------------|-----------|
[all assumptions]

---

## Next Steps

[Specific recommended actions based on findings]
```

---

## Phase 8: Summary

After writing, output:

```
Economy Simulation — [System Name]
=====================================
Scenarios:    [list]
Risk:         [inflation risk classification]
Concerns:     [N] BLOCKING, [N] MODERATE, [N] MINOR
Confidence:   [level]
Output:       docs/analytics/economy-sim-[slug].md

Next steps:
1. [Top priority concern and recommended fix]
2. If BLOCKING concerns exist: run /balance-check to verify formulas, then update the GDD
3. Run /ab-test after shipping changes to validate progression pacing in live data
4. Re-run /economy-simulation after GDD revisions to confirm improvement

Verdict: COMPLETE — economy projection produced.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 7 requires explicit approval
- Do not run game code — all projections are arithmetic from the GDD math model
- Every assumption must be logged — an undocumented assumption invalidates the projection
- BLOCKING concerns must be surfaced immediately; do not bury them in a long report
- This skill models the math, not the player experience — balance concerns from this
  skill should be validated against playtest data before acting on them unilaterally
- Escalate to `economy-designer` if the GDD math model is incomplete or contradictory
