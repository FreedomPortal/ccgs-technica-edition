---
name: demo-scope
description: "Define the demo's scope: what content is included, what's locked, target playthrough duration, save handling, and how the demo ends. Outputs design/demo/demo-scope.md. Run before /demo-build."
argument-hint: "(no argument) [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Read Prerequisites

Read the following if they exist:
- `design/gdd/game-concept.md` — core loop, scope, MVP content
- `design/demo/demo-scope.md` — if it already exists, this is an update run
- `production/stage.txt` — current dev stage
- `production/publishing/publishing-roadmap.md` — demo window context (Steam Next Fest, etc.)

If `design/gdd/game-concept.md` does not exist:
> "No game concept GDD found. Run `/design-system` first to establish the game's scope before defining a demo."
Stop.

---

## Phase 2: Gather Demo Context

Ask the following questions using `AskUserQuestion` (batch into one call):

**Question 1** — Demo purpose:
- Prompt: "What is the primary purpose of this demo?"
- Options:
  - Steam Next Fest submission
  - Always-on free demo (permanent on store page)
  - Press/influencer preview build
  - Internal playtest build
  - Other — I'll describe it

**Question 2** — Content boundary:
- Prompt: "How much of the game does the demo include?"
- Options:
  - First act / first zone only
  - Tutorial + one complete run/loop
  - Time-limited (e.g., 30 minutes then hard stop)
  - Feature-limited (full game content, certain systems disabled)
  - Custom — I'll describe it

**Question 3** — Demo end state:
- Prompt: "How does the demo end?"
- Options:
  - Hard stop with store redirect (wishlist / buy now prompt)
  - Loop back to the start
  - Fade to credits with no prompt
  - Custom — I'll describe it

**Question 4** — Save data handling:
- Prompt: "How should the demo handle save data?"
- Options:
  - Isolated save (demo progress never carries to full game)
  - Shared save (demo progress imports into full game on purchase)
  - No save at all (demo always starts fresh)

Store all answers for use in Phase 3.

---

## Phase 3: Draft Demo Scope Document

Spawn `game-designer` via Task with this prompt:

```
Draft a demo scope document for a game demo.

Game context (from game-concept.md):
[paste relevant content — MVP scope, core loop, content list]

Demo parameters (from user answers):
- Purpose: [answer 1]
- Content boundary: [answer 2]
- End state: [answer 3]
- Save handling: [answer 4]

Write a demo scope document with these sections:

## Overview
One paragraph: what this demo is, who it's for, and what it proves.

## Included Content
Bullet list of exactly what content, features, and systems are in the demo.
Be specific — name levels, parts, modes, or scenes by their GDD names.

## Excluded / Locked Content
Bullet list of full-game content that is disabled or hidden in the demo.
For each: note how it is locked (UI greyed out, code-gated, not present in build).

## Playthrough Flow
Step-by-step: what the player experiences from launch to demo end.
Include approximate time at each step.

## Target Playthrough Duration
- Minimum (skip everything): [X minutes]
- Expected (average player): [Y minutes]
- Maximum (completionist): [Z minutes]

## Demo End State
Describe exactly what happens when the demo ends: screen shown, text, CTA, links.

## Save Data Handling
Describe exactly how save data is isolated, shared, or reset.

## Content Lock Implementation Notes
For each excluded/locked item: one sentence on the implementation approach.
Flag any items that require significant engineering work to lock properly.

## Demo-Specific Acceptance Criteria
3–5 testable criteria that define a shippable demo (distinct from the full game's AC).

Do not invent content not in the game-concept GDD. Flag any scope decisions that need
the developer to resolve (mark as [DECISION NEEDED]).
```

Present the draft to the user. Discuss and revise until approved.

---

## Phase 4: Producer Feasibility Check

**Review mode check** — apply before spawning:
- `solo` → skip. Note: "PR-DEMO-SCOPE skipped — Solo mode."
- `lean` → skip. Note: "PR-DEMO-SCOPE skipped — Lean mode."
- `full` → spawn as normal.

Spawn `producer` via Task:

```
Review the following demo scope for feasibility.

[paste draft demo scope document]

Current dev stage: [stage]
Publishing context: [relevant publishing roadmap notes]

Assess:
1. Is the included content achievable at the current dev stage?
2. Are the content locks implementable without major engineering work?
3. Does the demo duration match the purpose (e.g., Steam Next Fest allows up to ~2 hours)?
4. Is the end state / CTA appropriate for the demo purpose?

Verdict: REALISTIC / CONCERNS / UNREALISTIC
One paragraph of reasoning. Flag specific items if CONCERNS or UNREALISTIC.
```

If UNREALISTIC: revise the scope before proceeding.
If CONCERNS: surface them and let the user decide whether to adjust.

---

## Phase 5: Write Demo Scope

Ask: "May I write the demo scope to `design/demo/demo-scope.md`?"

If yes, write the file, creating the directory if needed.

---

## Phase 6: Summary and Next Steps

```
Demo Scope — COMPLETE
======================
Output: design/demo/demo-scope.md
Included content: [X items]
Target playthrough: [Y–Z minutes]
End state: [description]
Save handling: [description]

[DECISION NEEDED items, if any]

Next steps:
- /demo-build — export and validate the demo build against this scope
- /demo-playtest — run a structured playtest focused on first impression and conversion
- /demo-feedback — after 2+ playtest sessions, synthesize patterns and get a go/no-go verdict
- /demo-polish — final polish pass before public release (run after feedback clears P1 blockers)

[If /demo-plan was not run first:]
Note: /demo-plan can define milestones, goals, and a risk register for the demo production effort.
```

---

## Collaborative Protocol

- Never invent content not established in the game GDD
- Always flag [DECISION NEEDED] rather than guessing on unresolved scope questions
- Never write to `design/demo/` without explicit approval
