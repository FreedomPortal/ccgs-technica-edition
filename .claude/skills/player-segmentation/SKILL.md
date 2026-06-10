---
name: player-segmentation
description: "Define player cohorts with behavioral thresholds and live ops lever mappings. Produces docs/analytics/player-segments.md. Use after initial analytics data is available to enable targeted live ops responses and personalized engagement."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Detect Current State

Read:
- `design/gdd/game-concept.md` — game title, genre, core loop, monetization model, target audience
- `docs/analytics/analytics-plan.md` — available events (determines which behavioral signals are observable)
- `docs/analytics/player-segments.md` — load if exists (update vs. create)
- `production/publishing/live-ops-strategy.md` — retention goals if exists

If no game concept exists, stop:
> "No game concept found. Run `/brainstorm` first."

---

## Phase 2: Determine Mode

If `docs/analytics/player-segments.md` already exists:
> "A segmentation document already exists. What would you like to do?"

Use `AskUserQuestion`:
- Options: "Review and update existing segments", "Add new segments", "Start fresh"

If no document exists: proceed to Phase 3.

---

## Phase 3: Confirm Data Availability

Use `AskUserQuestion`:
- Prompt: "Is live player data available to calibrate segment thresholds?"
- Options:
  - `Yes — live data available` — I have D1/D7/D30 data and can set real thresholds
  - `Partial — limited data` — I have some data but it's early; use data + informed estimates
  - `No — pre-launch design` — Design the segments now; calibrate thresholds post-launch

Record availability level — it determines whether thresholds are empirical or estimated,
and whether the output document is marked as Draft (pre-data) or Active.

---

## Phase 4: Define Segmentation Goals

Use `AskUserQuestion`:
- Prompt: "What is the primary purpose of player segmentation for this project?"
- Options:
  - `Retention targeting` — Identify at-risk players before they churn; trigger re-engagement
  - `Monetization optimization` — Find high-spend potential players; optimize store offers
  - `Feature adoption` — Identify players not using key systems; trigger tutorials or nudges
  - `Difficulty tuning` — Identify struggling vs. succeeding players; adjust difficulty curve
  - `All of the above` — Design comprehensive segments covering all goals

---

## Phase 5: Design Segments

Read `docs/analytics/analytics-plan.md` to extract the event taxonomy before spawning.
If no analytics plan exists, note available signals as "unknown — design placeholder thresholds."

Spawn the `growth-analyst` agent via Task with this prompt, substituting extracted values:

```
You are the growth-analyst for [GAME TITLE], a [GENRE] game.

Segmentation goal: [GOAL FROM PHASE 4]
Data availability: [AVAILABILITY FROM PHASE 3]
Available behavioral signals (events): [EVENT LIST FROM ANALYTICS PLAN, or "not yet defined"]
Core loop: [SUMMARY FROM game-concept.md]
Monetization model: [MODEL FROM game-concept.md]
Target audience: [AUDIENCE FROM game-concept.md]

Design a player segmentation framework. Produce:

1. Segment Definitions (3–7 segments)
   For each segment:
   - Name: a memorable label (e.g., "Power Players", "Casual Visitors", "At-Risk Churners")
   - Description: 1 sentence — who is this player?
   - Entry Criteria: specific behavioral thresholds (sessions, actions, spending, time-in-game)
     If data is unavailable, provide estimated thresholds marked as [ESTIMATE — calibrate post-launch]
   - Expected % of playerbase: rough size estimate with confidence level (High / Medium / Low)
   - Signal events: which tracked events identify this player
   - Exit criteria: what changes a player's segment membership

2. Segment Transition Map
   A simple table showing how players typically move between segments over time:
   - Which path is healthy (growing toward high-value segments)
   - Which path indicates churn risk
   - Time markers: typical segment duration before transition

3. Live Ops Lever Mapping
   For each segment, recommend 1–3 targeted live ops actions:
   - Lever name (e.g., "Win-Back Email", "Difficulty Assist Unlock", "VIP Early Access")
   - Goal: what behavior you want to change
   - Trigger: when to activate the lever (e.g., "48h since last session")
   - Risk: any player-trust concern (e.g., "may feel surveillance-y if too fast")

4. Measurement
   - Primary metric per segment: what improvement looks like
   - Recommended review cadence: how often to re-evaluate segment thresholds

If data availability is Pre-launch: explicitly mark all thresholds as
[ESTIMATE — calibrate with live data]. Add a calibration checklist at the end.
```

After the agent completes, present segments to the user for review.

---

## Phase 6: Review and Adjust

After presenting segments, ask:

Use `AskUserQuestion`:
- Prompt: "How would you like to proceed with the segment design?"
- Options:
  - `Accept all segments` — Write the document as presented
  - `Remove some segments` — I want fewer segments; I'll specify which to cut
  - `Revise thresholds` — The thresholds need adjustment; I'll give feedback

If adjustments are needed, handle inline, then return to this prompt.

---

## Phase 7: Write Document

Ask: "May I write the player segmentation to `docs/analytics/player-segments.md`?"

Wait for confirmation before writing.

Write the file:

```markdown
# Player Segmentation — [Game Title]
**Last updated:** [date]
**Status:** [Draft — pre-launch | Active — calibrated on live data]
**Segmentation goal:** [goal from Phase 4]

---

## Segments

### [Segment Name]
**Description:** [1-sentence description]
**Entry criteria:** [behavioral thresholds]
**Expected playerbase %:** [estimate + confidence]
**Signal events:** [list]
**Exit criteria:** [what changes segment membership]

[repeat for each segment]

---

## Segment Transition Map

| From | To | Typical Trigger | Health Signal |
|------|----|-----------------|---------------|
[from agent output]

---

## Live Ops Lever Mapping

| Segment | Lever | Goal | Trigger | Risk |
|---------|-------|------|---------|------|
[from agent output]

---

## Measurement

| Segment | Primary Metric | Review Cadence |
|---------|---------------|----------------|
[from agent output]

---

## Calibration Checklist (pre-launch segments only)

- [ ] After launch, review D7 data and adjust entry thresholds to match observed behavior
- [ ] Validate expected % against actual segment distribution — rebalance if off by >50%
- [ ] Check that signal events are being tracked before activating any live ops lever
- [ ] Set first threshold review date: [date — recommend 4 weeks post-launch]
```

---

## Phase 8: Summary

After writing, output:

```
Player Segmentation — [Game Title]
=====================================
Segments:  [N] segments defined
Status:    [Draft / Active]
Output:    docs/analytics/player-segments.md

Next steps:
1. Ensure signal events from each segment are tracked — check analytics-plan.md
2. Wire live ops levers to your retention platform or live-ops-strategy.md
3. Run /retention-analysis after 4+ weeks of data to validate churn predictions
4. Run /ab-test to test lever effectiveness for each high-priority segment

Verdict: COMPLETE — player segmentation framework produced.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 7 requires explicit approval
- Pre-launch thresholds are estimates; always mark them clearly and include a calibration checklist
- Segment names should be memorable and neutral — avoid labels that could feel dehumanizing
- Do not create more than 7 segments — cognitive overload makes segmentation unused
- Levers are recommendations, not mandates — the live-ops-designer decides which to activate
