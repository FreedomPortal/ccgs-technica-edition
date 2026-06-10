---
name: telemetry-design
description: "Design a focused event taxonomy to answer a specific business question. Narrower than /analytics-setup — this skill starts with one question and produces the minimum events needed to answer it. Produces docs/analytics/telemetry-[slug].md."
argument-hint: "[optional: business question or topic slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Detect Current State

Read:
- `docs/analytics/analytics-plan.md` — existing event taxonomy and platform (avoid duplication)
- `design/gdd/game-concept.md` — game title, genre, core loop, monetization model
- `.claude/docs/technical-preferences.md` — engine confirmation

If no analytics plan exists:
> "No analytics plan found. Consider running `/analytics-setup` first to choose
> a platform and design the full event taxonomy. `/telemetry-design` is best used
> for targeted event additions after the foundation is in place — but it can run
> standalone if you prefer a question-first approach."

Present the note, then proceed regardless (question-first is valid).

---

## Phase 2: Identify the Business Question

If the user provided an argument, use it as the starting question. Otherwise:

Use `AskUserQuestion`:
- Prompt: "What specific question do you need telemetry to answer?"
- Options:
  - `D7 drop-off` — Where and why are players leaving in the first week?
  - `Onboarding funnel` — Which tutorial step is causing the most first-session drop-off?
  - `Feature adoption` — Is a specific feature being discovered and used?
  - `Economy health` — Are players earning/spending currency at expected rates?
  - `Match/session pacing` — How long are sessions and what ends them?
  - `Custom` — I'll describe my own question

If "Custom", ask the user to describe the question in one sentence before proceeding.

Record the business question — every event designed in Phase 4 must trace back to it.

---

## Phase 3: Scope the Existing Coverage

If `docs/analytics/analytics-plan.md` exists, identify events already tracked that
partially address the business question. List them explicitly:

> "Your analytics plan already tracks: [list events]. These partially cover your
> question. The event design in Phase 4 will fill the gaps rather than duplicate."

If no overlap, proceed directly to Phase 4.

---

## Phase 4: Design Events

Spawn the `growth-analyst` agent via Task with this prompt, substituting values:

```
You are the growth-analyst for [GAME TITLE], a [GENRE] game.

Business question to answer: [QUESTION FROM PHASE 2]
Existing events already tracked: [LIST FROM PHASE 3, or "none"]
Game core loop: [SUMMARY FROM game-concept.md]

Design the minimum event set needed to answer the business question. Produce:

1. Event List
   For each event:
   - Name: [category].[action].[detail] (e.g., game.match.completed)
   - When it fires: exact trigger condition
   - Properties: each property with type and example value
   - Why it answers the question: one sentence linking this event to the business question

2. Priority Tier for each event:
   - MUST TRACK: without this event, the question cannot be answered
   - SHOULD TRACK: enriches the answer; implement if low-cost
   - NICE TO HAVE: optional context; add after core events are verified

3. Analysis Plan (2-4 sentences):
   How the events combine to answer the business question. What dashboard
   view or query produces the insight.

4. Gaps:
   Anything the question needs that cannot be answered with events alone
   (e.g., "requires session recording" or "requires A/B test — see /ab-test").

Keep the event list minimal. Do not add events that do not directly serve
the business question. If the question is already answerable with existing
events, say so and recommend running /retention-analysis or /ab-test instead
of adding more events.
```

After the agent completes, present the event list to the user for review.

---

## Phase 5: Review and Trim

After presenting the agent output, ask:

Use `AskUserQuestion`:
- Prompt: "How would you like to proceed?"
- Options:
  - `Accept as-is` — Write the event design document
  - `Trim to MUST TRACK only` — Remove SHOULD and NICE TO HAVE events before writing
  - `Revise` — I want to adjust specific events before writing

If "Revise", handle inline — ask what to change, update the event list in conversation,
then return to this prompt.

---

## Phase 6: Write Document

Ask: "May I write the telemetry design to `docs/analytics/telemetry-[slug].md`?"
(derive slug from the business question topic, e.g., `d7-dropoff`, `onboarding-funnel`)

Wait for confirmation before writing.

Create `docs/analytics/` if it does not exist. Write the file:

```markdown
# Telemetry Design — [Business Question]
**Last updated:** [date]
**Business question:** [exact question from Phase 2]
**Existing events reused:** [list or "none"]

---

## Event Design

### [Event Name]
- **When:** [trigger condition]
- **Properties:** [list with types]
- **Why:** [link to business question]
- **Priority:** MUST TRACK / SHOULD TRACK / NICE TO HAVE

[repeat for each event]

---

## Analysis Plan

[How events combine to answer the question. What query or funnel view to build.]

---

## Gaps

[Anything outside event tracking scope — A/B test needed, session recording required, etc.]

---

## Integration Checklist

- [ ] Events approved and added to `docs/analytics/analytics-plan.md` (Event Taxonomy section)
- [ ] Events instrumented in game code (programmer task)
- [ ] Verified: at least one event visible in dashboard after first test session
- [ ] Analysis query / funnel configured in analytics platform
```

---

## Phase 7: Summary

After writing, output:

```
Telemetry Design — [Business Question]
========================================
Question:  [business question]
Events:    [N] events ([M] MUST TRACK, [K] SHOULD TRACK)
Output:    docs/analytics/telemetry-[slug].md

Next steps:
1. Add these events to docs/analytics/analytics-plan.md (Event Taxonomy section)
2. Assign instrumentation as a programmer story — reference this document
3. After 2+ weeks of data, run /retention-analysis or /ab-test to act on findings

Verdict: COMPLETE — telemetry event design produced.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 6 requires explicit approval
- This skill designs events — it does NOT set up the analytics platform (/analytics-setup) or analyze existing data (/retention-analysis)
- Always trace every event back to the business question — if an event can't be justified, cut it
- If the question is already answerable with existing events, tell the user rather than adding redundant tracking
