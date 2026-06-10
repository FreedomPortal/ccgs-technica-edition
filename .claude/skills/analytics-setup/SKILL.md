---
name: analytics-setup
description: "Design the analytics and telemetry plan for the game. Walks through platform choice, event taxonomy, key funnels, and privacy compliance. Invokes the analytics-engineer agent to produce docs/analytics/analytics-plan.md."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, WebSearch
---

When this skill is invoked:

## Phase 1: Detect Current State

Read:
- `design/gdd/game-concept.md` — extract game title, genre, core mechanics, target audience, platforms
- `.claude/docs/technical-preferences.md` — engine and target platform confirmation
- `docs/analytics/analytics-plan.md` — load if exists (update mode vs. create mode)
- `production/publishing/publishing-roadmap.md` — current dev stage if available

If no game concept exists, stop:
> "No game concept found. Run `/brainstorm` first — analytics design depends on
> knowing your core game loop, monetization model, and target audience."

---

## Phase 2: Determine Mode

If `docs/analytics/analytics-plan.md` already exists:
> "An analytics plan already exists. Do you want to review and update it,
> or start fresh?"

Use `AskUserQuestion`:
- Options: "Review and update existing", "Start fresh (archive the old one)", "Just add new events"

If no plan exists: proceed to Phase 3.

---

## Phase 3: Understand Goals

Use `AskUserQuestion`:
- Prompt: "What is the primary reason you want analytics in this game?"
- Options:
  - `Balance tuning` — I want data on which builds/strategies win/lose to inform balance decisions
  - `Retention analysis` — I want to understand where players drop off and why
  - `Onboarding funnel` — I want to know if players understand the core loop
  - `Launch health` — I want crash rates, session lengths, and daily active users post-launch
  - `All of the above` — comprehensive tracking from the start

Record the goal — it determines which events are high-priority vs. optional.

---

## Phase 4: Platform Choice

Present options with honest tradeoffs for an indie game on Steam running [ENGINE]:

> **Analytics platform options:**
>
> **A) GameAnalytics (recommended for solo devs)**
> - Free up to 5B events/month — effectively unlimited for an indie game
> - Pre-built dashboards: DAU, session length, retention curves, progression funnels
> - [ENGINE] integration: REST API (no official [ENGINE] SDK; community solutions exist)
> - Tradeoffs: proprietary platform, US data storage, limited self-serve data export
>
> **B) Steam Stats + Achievements**
> - Free, built into Steam — no separate account needed
> - Best for: public-facing achievement tracking, basic playtime and ownership stats
> - Tradeoffs: very limited event granularity; no custom funnels or behavioral data
>
> **C) PostHog (self-hosted or cloud)**
> - Open source — can self-host on a small VPS for ~$5/mo
> - Full event tracking, funnels, session recording, and A/B tests
> - Tradeoffs: more setup work; self-hosting requires ongoing server maintenance
>
> **D) Custom (log to file / custom backend)**
> - Zero cost, zero external dependency
> - Best for: developers who want event data without third-party involvement
> - Tradeoffs: no built-in dashboards — you build your own analysis tooling
>
> **E) Skip for now**
> - Valid for a jam game or early prototype. Decision will be documented.

Use `AskUserQuestion`:
- Prompt: "Which analytics approach fits your project?"
- Options: `GameAnalytics (recommended)`, `Steam Stats + Achievements`, `PostHog`, `Custom log-to-file`, `Skip for now`

---

## Phase 5: Event Taxonomy Design

Read `design/gdd/game-concept.md` to extract: game title, genre, core loop description,
and any mechanics relevant to tracking (e.g., match structure, progression, monetization model).

Spawn the `analytics-engineer` agent via Task with this prompt, substituting the values
extracted from `game-concept.md`:

```
You are the analytics-engineer for [GAME TITLE], a [GENRE] game targeting [PLATFORMS],
built in [ENGINE].

Read design/gdd/game-concept.md for the full game context before designing the event taxonomy.

Developer's analytics goal: [INSERT GOAL FROM PHASE 3]
Chosen platform: [INSERT PLATFORM FROM PHASE 4]

Design the full telemetry event taxonomy for this game. Produce:

1. Core event list — every event to track, using the naming convention [category].[action].[detail]
   Example: game.match.started, game.match.completed, ui.menu.settings_opened

2. Event properties — for each event, what properties are attached
   Example: game.match.completed → { outcome: "win"|"loss", rounds: int, duration_sec: float }

3. Priority tier for each event:
   - MUST TRACK: missing this event breaks balance analysis or the key funnel
   - SHOULD TRACK: high value for design decisions; implement in first sprint
   - NICE TO HAVE: low priority; add after core loop is stable

4. Key funnels — 3 to 5 player journeys to monitor (e.g., Tutorial Completion Funnel,
   First Win Funnel, Match Loop Funnel). For each funnel: list the events that mark
   each step, in order.

5. Session-level metrics — what to track at session start/end (session length, match
   count per session, return interval)

6. Privacy notes — flag any PII risk in the proposed event design and recommend an
   opt-out mechanism the developer should implement.

Format the output as a structured plan document. Do not write any game code.
```

After the agent completes, present the taxonomy to the user for review before writing anything.

---

## Phase 6: [ENGINE] Integration Notes

Before including any code in the output document:
1. Check `docs/engine-reference/[ENGINE]/` for any breaking changes to networking, 
   file access, or JSON APIs in recent versions of [ENGINE]
2. If changes are found, adjust the snippet accordingly
3. If uncertain about a specific API call, use WebSearch to verify against the
   official [ENGINE] documentation before including it

Include an [ENGINE]-specific integration section in the plan based on the platform chosen:

### If GameAnalytics

> **Integration method:** REST API (check for official [ENGINE] SDK first).
> Batch events and send on session end to minimize network overhead during gameplay.
>
> Recommended pattern: Use a singleton/autoloaded script `analytics_manager` that queues events
> to an internal array and flushes them on application exit or backgrounding.
>
> Community resources: search "GameAnalytics [ENGINE] REST API" on GitHub for
> current integration examples — verify any library you find targets your current engine version.

### If PostHog

> **Integration method:** REST API via HTTP requests.
> Endpoint: `POST [your-host]/capture/` with JSON body:
> `{ "api_key": KEY, "event": name, "distinct_id": player_uuid, "properties": {...} }`
>
> Player UUID: generate once at first launch, store in local persistent storage.
> Never use a hardware ID or any value that could identify the player personally.

### If Steam Stats

> **Integration method:** Steamworks SDK or relevant [ENGINE] plugin.
> Stats must be defined in the Steamworks partner portal before they can be set in code.
> Only add the necessary Steam libraries to `technical-preferences.md` when this work begins.

### If Custom log-to-file

> **Integration method:** Write events as JSON Lines to a local persistent file.
> Each line: `{ "ts": unix_timestamp, "event": name, "props": {...} }`
>
> Verify current file I/O APIs against `docs/engine-reference/[ENGINE]/` before
> using — file APIs often change between major engine versions.

---

## Phase 7: Write Plan

Ask: "May I write the analytics plan to `docs/analytics/analytics-plan.md`?"

Wait for confirmation before writing.

Create `docs/analytics/` if it does not exist. Write the file with this structure:

```markdown
# Analytics Plan — [Game Title]
**Last updated:** [date]
**Platform:** [chosen platform]
**Primary goal:** [goal from Phase 3]

---

## Platform Decision

[Chosen platform + rationale. If "Skip for now", state: "Analytics deferred.
Reason: [user's reason]. Revisit at: [milestone or stage]."]

### [ENGINE] Integration Approach

[Integration notes from Phase 6 — verified against docs/engine-reference/[ENGINE]/]

---

## Event Taxonomy

[Full output from analytics-engineer agent — Phase 5]

### Priority Tiers

| Tier | Meaning |
|------|---------|
| MUST TRACK | Missing this event breaks balance analysis or a key funnel |
| SHOULD TRACK | High value; implement in first sprint after core loop is stable |
| NICE TO HAVE | Low priority; add after launch or when data gaps are identified |

---

## Key Funnels

[Funnels from analytics-engineer agent]

---

## Session Metrics

[Session-level metrics from agent output]

---

## Privacy Compliance

[Privacy notes from agent output]

**Minimum steps before shipping:**
1. Player IDs are anonymous UUIDs — never hardware IDs or account details
2. Settings screen includes an Analytics Opt-Out toggle (required for GDPR compliance)
3. Privacy policy references data collection (required before Steam store page goes live)

---

## Implementation Checklist

- [ ] `analytics_manager` singleton/script created
- [ ] Anonymous player UUID generated on first launch and persisted locally
- [ ] Opt-out toggle in Settings screen wired to analytics_manager
- [ ] All MUST TRACK events implemented and verified (at least one event visible in dashboard)
- [ ] Privacy policy updated before store page goes live
```

---

## Phase 8: Summary

After writing, output:

```
Analytics Plan — [Game Title]
==============================
Platform:      [chosen platform]
Goal:          [primary goal]
Events:        [N] events designed ([M] MUST TRACK, [K] SHOULD TRACK)
Funnels:       [J] funnels defined
Output:        docs/analytics/analytics-plan.md

Next steps:
1. Implement analytics_manager as an [ENGINE] singleton/autoload
2. Start with MUST TRACK events — wire session.start and session.end first
3. Run /architecture-decision to record the analytics platform choice as an ADR
4. For targeted event design around a specific business question (e.g., "why is
   D7 retention low?"), use /telemetry-design — it produces a focused event set
   without redesigning the full taxonomy
5. After 2+ weeks of live data, use /retention-analysis to classify your
   retention curve and identify drop-off points against genre benchmarks

Verdict: COMPLETE — analytics plan designed.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 7 requires explicit approval before any write
- The analytics-engineer agent produces the event taxonomy — always present it
  for user review before incorporating into the plan document
- If the user chooses "Skip for now", still write the plan — document the deferred
  decision with a reason and a revisit milestone
- For GameAnalytics and PostHog: always check if an official [ENGINE] SDK exists
  and suggest REST API integration as a fallback.
- If the game concept reveals an unusual genre or platform not covered by Phase 4's
  options, present an appropriate alternative and explain the tradeoffs