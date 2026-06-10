---
name: live-ops-plan
description: "Design the post-launch live service strategy: content cadence calendar, seasonal events, player retention mechanics, engagement metrics, and economy health monitoring. Produces production/publishing/live-ops-strategy.md. Complements /live-event (individual events) — this skill creates the overarching plan that /live-event operates within."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Detect Current State

Read:
- `design/gdd/game-concept.md` — game title, genre, core loop, monetization model, target audience
- `production/publishing/live-ops-strategy.md` — load if exists (update vs. create)
- `production/publishing/publishing-roadmap.md` — launch window and current stage
- `design/monetization/monetization-plan.md` — if it exists, read revenue model context
- `docs/analytics/retention-*.md` — load any existing retention analyses (pre-fills Phase 3 with data-informed retention problem selection)

If no game concept exists, stop:
> "No game concept found. Run `/brainstorm` first — live ops design depends on
> knowing the core loop, monetization model, and target audience."

---

## Phase 2: Determine Mode

If `production/publishing/live-ops-strategy.md` already exists:
> "A live ops strategy already exists. What would you like to do?"

Use `AskUserQuestion`:
- Options: "Review and update existing", "Add new content to the calendar", "Start fresh (archive the old one)"

If no plan exists: proceed to Phase 3.

---

## Phase 3: Understand the Live Ops Context

Use `AskUserQuestion`:
- Prompt: "What is your intended post-launch live service model?"
- Options:
  - `Seasonal updates` — major content drops on a seasonal cadence (3–4 per year)
  - `Monthly content` — smaller updates each month (patches + events)
  - `Event-driven` — irregular events tied to calendar moments (holidays, anniversaries)
  - `Maintenance mode` — no planned live service; bug fixes only post-launch

Record the model — it drives the calendar density and effort estimates.

Use `AskUserQuestion`:
- Prompt: "What is the primary retention problem you want live ops to solve?"
- Options:
  - `Day-7 retention` — players drop off in the first week
  - `Day-30 retention` — players plateau after the initial burst
  - `Reactivation` — players stop playing but could come back with new content
  - `Monetization` — retained players exist but aren't spending

---

## Phase 4: Spawn Live Ops Designer

Read `design/gdd/game-concept.md` to extract game title, genre, core loop, and monetization
model before spawning the agent.

Spawn the `live-ops-designer` agent via Task with this prompt, substituting extracted values:

```
You are the live-ops designer for [GAME TITLE], a [GENRE] game targeting [PLATFORMS].
Core loop: [CORE LOOP SUMMARY from game-concept.md]
Monetization model: [MODEL — if unknown, note it]
Post-launch model chosen by developer: [MODEL FROM PHASE 3]
Primary retention problem: [PROBLEM FROM PHASE 3]

Design the post-launch live service strategy. Produce:

1. Content Cadence Calendar
   - A 12-month post-launch content plan with:
     - Month-by-month update schedule
     - Each update categorized: Major Content / Minor Content / Event / Patch
     - Effort estimate for a solo developer (Low / Medium / High)

2. Seasonal Events Design (top 3–5 events)
   For each event:
   - Name and theme
   - Duration (days)
   - Player hook: what does it offer that normal play doesn't?
   - Content requirement: new assets needed (Low / Medium / High)
   - Optimal calendar timing (e.g., Winter Holidays, Summer, Anniversary)

3. Retention Mechanics (3–5 recommendations)
   For each mechanic:
   - Name and description
   - Addresses which retention window (Day-7 / Day-30 / Reactivation)
   - Implementation complexity (Low / Medium / High)
   - Risk: any player-trust concerns (e.g., FOMO, pay-to-access)

4. Engagement Metrics
   - Which metrics to watch post-launch (DAU, D7/D30 retention rate, session length,
     return interval, event participation rate)
   - Alert thresholds: when each metric signals a live ops response is needed
   - Recommended review cadence (weekly dashboard, monthly deep-dive)

5. Economy Health Monitoring
   - Key economy indicators to track (currency balance, item acquisition rates,
     sink/faucet ratios if applicable)
   - Warning signs of economy inflation or deflation
   - Recommended correction levers (drop rate adjustment, pricing, limited offers)

6. Solo Developer Scope Filter
   - Flag any recommendations above that are realistically too expensive for a
     solo dev without additional staff
   - Suggest a "Minimum Viable Live Ops" slice: the 3–5 highest-impact items
     a solo developer should prioritize

Format the output as a structured strategy document. Do not write any game code.
```

After the agent completes, present the strategy to the user for review before writing anything.

---

## Phase 5: Relationship to /live-event

After presenting the strategy output, include this note:

> **Relationship to `/live-event`:**
> This strategy defines the plan — the cadence, budget, and goals.
> Use `/live-event [event name]` to design the mechanics and implementation
> details for each individual event in the calendar.
>
> The live ops strategy belongs in `production/publishing/live-ops-strategy.md`.
> Individual event designs go in `design/live-events/[event-slug].md`.

---

## Phase 6: Write Strategy

Ask: "May I write the live ops strategy to `production/publishing/live-ops-strategy.md`?"

Wait for confirmation before writing.

Create `production/publishing/` if it does not exist. Write the file with this structure:

```markdown
# Live Ops Strategy — [Game Title]
**Last updated:** [date]
**Live service model:** [chosen model]
**Primary retention goal:** [retention problem]

---

## Executive Summary

[2–3 sentence summary of the overall approach — solo dev scope acknowledged]

---

## Content Cadence Calendar

[12-month table from agent output]

---

## Seasonal Events

[Top 3–5 events from agent output]

---

## Retention Mechanics

[3–5 recommendations from agent output]

---

## Engagement Metrics

| Metric | Alert Threshold | Review Cadence |
|--------|----------------|----------------|
[from agent output]

---

## Economy Health Monitoring

[From agent output]

---

## Minimum Viable Live Ops (Solo Dev Slice)

[The 3–5 highest-impact items flagged by agent for solo developer scope]

---

## Implementation Notes

- Use `/live-event [name]` to design the mechanics for each individual event
- Use `/analytics-setup` to ensure the engagement metrics above are tracked
- Review this document at each milestone; update the calendar as content ships
```

---

## Phase 7: Summary

After writing, output:

```
Live Ops Strategy — [Game Title]
==================================
Model:         [live service model]
Goal:          [retention goal]
Calendar:      12-month content plan
Events:        [N] seasonal events designed
Retention:     [N] mechanics recommended
Output:        production/publishing/live-ops-strategy.md

Next steps:
1. Use /live-event [event name] to detail each event in the calendar
2. Use /analytics-setup to wire up the engagement metrics listed above
3. Run /retention-analysis after 2+ weeks of live data to identify which
   segments are churning and validate that retention mechanics are working
4. Run /balance-check after launch to validate economy health indicators

Verdict: COMPLETE — live ops strategy designed.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 6 requires explicit approval before any write
- The live-ops-designer agent produces the strategy content — always present it for user review before incorporating into the output document
- Flag any recommendations that require sustained effort a solo developer cannot sustain — the solo dev scope filter in Phase 4 is mandatory
- Do not duplicate `/live-event` — this skill creates the strategic plan; individual event design belongs in `/live-event`
- If the developer chose "Maintenance mode", still write the document — document the decision with rationale and note what would trigger a reconsideration (e.g., "If Day-30 retention falls below X%")
