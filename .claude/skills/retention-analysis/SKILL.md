---
name: retention-analysis
description: "Analyze player retention curves: classify curve shape, identify drop-off points, and compare against genre benchmarks. If no data is available yet, design the retention monitoring framework. Produces docs/analytics/retention-[slug].md."
argument-hint: "[optional: analysis slug or topic]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
---

When this skill is invoked:

## Phase 1: Detect Current State

Read:
- `docs/reference/analytics/genre-benchmarks.md` — genre median retention benchmarks for comparison
- `docs/analytics/analytics-plan.md` — confirm retention events are tracked (session.start, return interval)
- `docs/analytics/player-segments.md` — existing segment definitions if available
- `design/gdd/game-concept.md` — game title, genre, target audience

### Benchmark Source Selection

If `docs/reference/analytics/genre-benchmarks.md` exists, read it and present a summary of the
stored data to the user:

> **Stored benchmarks** (last updated: [date from file]):
> Mobile median — D1: ~15%, D7: ~3.4–3.9%, D30: <3%
> Mobile top-25% target — D1: 26–28%, D7: 7–8%, D30: ~1.6–1.8%
> PC/Steam median — D7: <4%, D30: ~0.7%
> (Source: GameAnalytics 2025/2026, Adjust, AppsFlyer, Mistplay, Sensor Tower)

Use `AskUserQuestion`:
- Prompt: "Which benchmark data should the analysis use?"
- Options:
  - `A — Use stored data` — Use the figures in docs/reference/analytics/genre-benchmarks.md as-is
  - `B — WebSearch for newer data` — Run a new web search for more recent benchmarks, then update the reference file
  - `C — Provide my own data` — I have access to current reports or platform-specific data; I'll supply the numbers

**If A:** Load benchmarks from the file and proceed to Phase 2.

**If B:** Use WebSearch to find updated D1/D7/D30 benchmarks (at least 3 sources). Present the
findings. Ask: "May I update `docs/reference/analytics/genre-benchmarks.md` with the new data?"
Wait for confirmation, then update the file. Note the date of the WebSearch in the Refresh Notes section.
Then proceed to Phase 2 using the updated data.

**If C:** Ask the user to provide the benchmark values they want to use:
> "Provide your benchmark values in this format:
> Platform: [mobile / PC / both]
> D1: [%], D7: [%], D30: [%], D60: [%] (optional), D90: [%] (optional)
> Source: [where the data came from]"
>
> After collecting: "May I update `docs/reference/analytics/genre-benchmarks.md` with your data?"
> Wait for confirmation, then add the user's data as a new section in the reference file with the
> source noted. Proceed to Phase 2 using the user-provided benchmarks.

If `docs/reference/analytics/genre-benchmarks.md` does NOT exist:
> "Genre benchmark file not found. Run `/retention-analysis` without existing data first — it will
> create the reference document. For now, comparisons will note 'benchmark unavailable'."
Proceed to Phase 2 without benchmark comparison.

---

## Phase 2: Determine Mode

Use `AskUserQuestion`:
- Prompt: "What would you like to do?"
- Options:
  - `Analyze live data` — I have D1/D7/D30 (or more) data to analyze now
  - `Design monitoring framework` — No data yet; design what to measure and how
  - `Update prior analysis` — Load an existing retention analysis and add new data

If "Update prior analysis", list existing `docs/analytics/retention-*.md` files and ask
which to update. Load the selected file as context before proceeding to Phase 3.

---

## ANALYSIS MODE (live data or update)

### Analysis Phase 3: Collect Data

Ask the user to provide retention data:

> "Please provide your retention data in this format:
>
> D1: [%] (players who returned on Day 1)
> D7: [%]
> D14: [%] (if available)
> D30: [%]
> D60: [%] (if available)
> D90: [%] (if available)
>
> Also note:
> - Total players in cohort: [N]
> - Cohort start date: [date]
> - Platform(s): [Steam / mobile / web]
> - Any known events during the period (updates, promotions, bugs): [list or none]"

If the user provides partial data (e.g., only D1 and D7), proceed — note which
windows are unavailable and flag them in the output.

### Analysis Phase 4: Classify and Analyze

Spawn the `growth-analyst` agent via Task with this prompt:

```
You are the growth-analyst for [GAME TITLE], a [GENRE] game.

Retention data:
[PASTE DATA FROM PHASE 3]

Genre benchmarks (from docs/reference/analytics/genre-benchmarks.md):
[PASTE RELEVANT BENCHMARK ROWS, or "unavailable"]

Known context: [EVENTS/FACTORS NOTED BY USER, or "none"]

Perform retention analysis:

1. Curve Classification
   Classify the overall curve shape:
   - HEALTHY DECAY: D1 moderate, decays gradually, flattens by D30 — sustainable retention
   - CLIFF DROP: sharp drop at a specific window (e.g., 60% → 12% between D7 and D14) — indicates
     a specific failure point (end of content, difficulty wall, live ops gap)
   - FLAT DECAY: strong D1 but linear decline with no plateau — engagement loop not stickiness
   - RAMP: retention improves at later windows — word-of-mouth or content update driven
   - VOLATILE: irregular pattern likely indicating cohort contamination or measurement issues

2. Drop-off Identification
   For each retention window where decline exceeds 50% of the prior window:
   - Flag as a DROP-OFF POINT
   - List likely causes based on typical game design patterns at this stage:
     e.g., D7 cliff often = tutorial ends + nothing to return for; D30 cliff = content exhaustion
   - Suggest which events in the analytics plan would pinpoint the exact cause
   - Rate confidence: High (classic pattern) / Medium (plausible) / Low (speculative)

3. Benchmark Comparison
   For each window with benchmark data:
   - Compare to genre median: above / at / below median
   - Calculate gap in percentage points
   - Flag if below median by >5pp as an ACTION ITEM
   If benchmarks unavailable: note "no benchmark available for [GENRE] — comparison skipped"

4. Root Cause Hypotheses (top 3)
   For the most significant drop-off point(s), list 3 hypotheses ordered by likelihood:
   - Each hypothesis: what it means mechanically + what data would confirm or rule it out

5. Recommended Actions
   For each action, specify:
   - What to change (design, live ops lever, A/B test, additional tracking)
   - Which player segment is most affected (cross-reference docs/analytics/player-segments.md if available)
   - Priority: HIGH (>5pp below benchmark or curve classified as CLIFF) / MEDIUM / LOW
   - Suggested next skill: /telemetry-design, /ab-test, or /live-ops-plan

6. Monitoring Cadence Recommendation
   How often to re-run this analysis given the current curve health:
   - CLIFF or FLAT: weekly until resolved
   - HEALTHY DECAY: monthly check
   - VOLATILE: fix measurement issues before re-analyzing
```

Present analysis to user before writing.

### Analysis Phase 5: Write Report

Ask: "May I write the retention analysis to `docs/analytics/retention-[slug].md`?"
(slug = cohort start date or topic, e.g., `retention-2026-06-01.md`)

Wait for confirmation.

```markdown
# Retention Analysis — [Game Title]
**Analyzed:** [date]
**Cohort:** [start date], [N] players
**Platform:** [platforms]
**Curve classification:** [type]

---

## Retention Data

| Window | Rate | vs. Genre Median | Status |
|--------|------|-----------------|--------|
| D1 | [%] | [+/- pp or N/A] | [above/at/below/N/A] |
| D7 | [%] | [+/- pp or N/A] | |
| D14 | [%] | N/A | |
| D30 | [%] | [+/- pp or N/A] | |
| D60 | [%] | N/A | |
| D90 | [%] | [+/- pp or N/A] | |

---

## Curve Classification: [TYPE]

[1–2 sentence description of the curve shape and what it indicates]

---

## Drop-off Points

[For each flagged drop-off: window, magnitude, likely causes, confidence]

---

## Benchmark Gaps — Action Items

[Only windows where gap is >5pp below median — listed with priority]

---

## Root Cause Hypotheses

1. [Hypothesis 1 — most likely] — confirmed by: [data/event]
2. [Hypothesis 2]
3. [Hypothesis 3]

---

## Recommended Actions

| Action | Segment | Priority | Next Step |
|--------|---------|----------|-----------|
[from agent output]

---

## Context Notes

[Known events, promotions, or factors during the cohort period]

---

## Monitoring Cadence

[Weekly / Monthly / Fix measurement first]
Next analysis recommended: [date]
```

Output after writing:
```
Retention Analysis — [Game Title]
====================================
Cohort:       [N] players, starting [date]
Curve:        [classification]
Key finding:  [top drop-off or standout]
Output:       docs/analytics/retention-[slug].md

Next steps:
1. [Top priority action from analysis]
2. Run /ab-test to test proposed changes
3. Run /telemetry-design if drop-off point needs better event coverage
4. Re-run /retention-analysis per recommended cadence

Verdict: COMPLETE — retention analysis produced.
```

---

## FRAMEWORK MODE (no data yet)

### Framework Phase 3: Design Measurement Plan

Spawn the `growth-analyst` agent via Task:

```
You are the growth-analyst for [GAME TITLE], a [GENRE] game.
No live retention data is available yet. Design the retention monitoring framework.

Produce:
1. Retention windows to track: which D-intervals matter for this genre + why
2. Events required: which analytics events must be implemented to calculate each window
3. Cohort definition: how to define a cohort start (first session? tutorial completion?)
4. Dashboard spec: what the retention dashboard should show (table, curve chart, benchmark overlay)
5. Alert thresholds: what numbers trigger a live ops review
6. Baseline expectations: estimated D1/D7/D30 targets based on genre benchmarks
   (load from docs/reference/analytics/genre-benchmarks.md if available)
7. First analysis trigger: recommend when to run /retention-analysis for the first time
   (e.g., "after 500 players have reached D7" or "4 weeks post-launch, whichever comes first")
```

Present framework to user.

### Framework Phase 4: Write Framework

Ask: "May I write the retention monitoring framework to `docs/analytics/retention-framework.md`?"

Wait for confirmation. Create `docs/analytics/` if needed. Write the file.

After write, output:

```
Retention Monitoring Framework — [Game Title]
===============================================
Windows:    [N] retention windows defined
Events:     [N] events required
Dashboard:  [description]
Output:     docs/analytics/retention-framework.md

Next steps:
1. Implement required events — assign as programmer stories
2. Run /retention-analysis once [N] players have reached D7 (or 4 weeks post-launch)
3. Run /telemetry-design if additional event coverage is needed

Verdict: COMPLETE — retention monitoring framework produced.
```

---

## Collaborative Protocol

- **Never write files without asking** — write gate in Analysis Phase 5 and Framework Phase 4
- Curve classification is a hypothesis, not a diagnosis — always list alternative explanations
- Benchmarks are reference points, not hard pass/fail targets — genre varies widely
- Drop-off hypotheses must link to specific observable data — no unfounded assertions
- If data coverage is thin (only D1 + D7), label the analysis as PARTIAL and avoid over-interpreting later windows

---

## Recommended Next Steps

Verdict: COMPLETE — retention analysis or framework produced.

- Run `/ab-test` to test changes proposed by the analysis
- Run `/telemetry-design` if drop-off point needs better event coverage
- Run `/player-segmentation` to map retention segments to live ops levers
- Re-run `/retention-analysis` per recommended monitoring cadence
