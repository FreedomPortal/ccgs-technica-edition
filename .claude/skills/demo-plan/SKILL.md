---
name: demo-plan
description: "Plan the demo production effort: set goals, identify target event/window, define milestones, estimate effort, and produce a risk register. Outputs design/demo/demo-plan.md. Run before /demo-scope for any non-trivial demo effort."
argument-hint: "[--early-access] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

## Phase 0: Resolve Flags and Review Mode

**Early Access mode:** Check `$ARGUMENTS` for `--early-access`. Store as `EA_MODE = true/false`.
When EA mode is active, the plan includes EA-specific sections (pricing strategy, roadmap commitments,
exit timeline) and the campaign's sub-stages extend to `Publishing` → `Live` after `Released`.

**Review mode:**
1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Read Prerequisites

Read the following if they exist:
- `design/gdd/game-concept.md` — core loop, MVP content list, scope
- `design/demo/demo-scope.md` — if it exists, this is a re-plan after scope was defined
- `design/demo/demo-plan.md` — if it exists, this is an update run; note current milestone status
- `production/stage.txt` — current dev stage
- `production/publishing/publishing-roadmap.md` — relevant events (Steam Next Fest, press window, etc.)

If `design/gdd/game-concept.md` does not exist:
> "No game concept GDD found. Run `/brainstorm` and `/design-system` first to establish the game before planning a demo."
Stop.

---

## Phase 2: Gather Demo Production Context

Ask the following using `AskUserQuestion` (batch into one call):

**Question 1** — Target event or window:
- Prompt: "What is this demo targeting?"
- Options:
  - Steam Next Fest (specify which season)
  - Always-on free demo on store page
  - Press/influencer preview (specify date)
  - Internal milestone or investor demo
  - No specific event — just planning the effort
  - Other — I'll describe it

**Question 2** — Hard deadline:
- Prompt: "Is there a fixed go-live date for the demo?"
- Options:
  - Yes — [user specifies date]
  - Not yet — I want a milestone plan based on current dev stage
  - No deadline — exploratory planning only

**Question 3** — Team capacity:
- Prompt: "Who is working on the demo?"
- Options:
  - Solo developer
  - Small team (2–4 people)
  - Full team (5+)
  - Contractor support available

**Question 4** — Demo-first or game-first:
- Prompt: "What is the development priority relationship?"
- Options:
  - Demo is the current top priority — everything else pauses
  - Demo runs in parallel with main game dev
  - Demo is a future milestone — planning ahead only

Store all answers for Phase 3.

**If `EA_MODE = true`**, ask one additional batch using `AskUserQuestion`:

**Question 5** — EA pricing strategy:
- Prompt: "What is your Early Access pricing approach?"
- Options:
  - Discount from planned 1.0 price (e.g., 20–30% off) — standard EA signal
  - Same as planned 1.0 price — uncommon; requires strong content justification
  - Not decided yet — I'll figure it out before publishing

**Question 6** — EA roadmap commitments:
- Prompt: "What are you committing to players before 1.0?"
- Options:
  - I have a specific feature list — I'll describe it
  - I know the content areas but not specific features yet
  - I'll communicate direction only, no specific commitments

**Question 7** — EA exit timeline:
- Prompt: "When do you expect to exit Early Access?"
- Options:
  - Fixed target date — [user specifies]
  - Within 6 months
  - 6–12 months
  - 12+ months
  - Unknown — depends on player feedback

Store all EA answers. These feed the EA-specific sections in Phase 3.

---

## Phase 3: Draft Demo Production Plan

Spawn `producer` via Task with this prompt:

```
Draft a demo production plan.

Game context:
[paste relevant sections from game-concept.md: core loop, content scope, current dev stage]

Publishing context:
[paste relevant publishing-roadmap.md sections if present]

Demo parameters:
- Target event/window: [answer 1]
- Hard deadline: [answer 2]
- Team capacity: [answer 3]
- Priority relationship: [answer 4]

If design/demo/demo-scope.md exists, include scope context:
[paste included content list and playthrough duration]

Write a demo production plan with these sections:

## Overview
One paragraph: what this demo is, when it needs to be ready, and the production approach.

## Goals
2–4 measurable goals for the demo (e.g., "achieve 80% demo completion rate in playtest", 
"generate 500 wishlists in first week", "receive press coverage before launch").
Each goal should be testable — not "make a great first impression" but "75%+ of playtesters 
say they would wishlist or buy".

## Target Event / Window
The specific event or date this demo targets, with submission deadlines if known.
For Steam Next Fest: include the Steamworks submission deadline (typically ~2 weeks before event).

## Milestones
Ordered list of milestones from now to go-live. For each:
- Name
- Exit criteria (what must be true for this milestone to be complete)
- Estimated duration from current date
- Dependencies (what must precede it)

Recommended milestones:
1. Scope Locked (`/demo-scope` complete, no further scope changes)
2. Content Feature Complete (all included content playable end-to-end)
3. Content Gates Implemented (excluded content locked in code)
4. First Internal Build (`/demo-build` PASS)
5. First Playtest Round (`/demo-playtest` ×3 sessions)
6. Iteration Complete (all conversion blockers resolved)
7. Polish Pass Complete (`/demo-polish` PASS)
8. Final Build + Smoke Check
9. Go-Live / Submission

Adjust milestones for the team size and deadline provided.

## Effort Estimate
Summary table:
| Phase | Estimated effort |
|-------|-----------------|
| Content gating | Xh |
| Demo build + smoke | Xh |
| Playtest coordination | Xh |
| Iteration on blockers | Xh |
| Polish pass | Xh |
| **Total** | **Xh** |

Note clearly that these are rough estimates — flag any phase where the estimate is particularly uncertain.

## Risk Register
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
List 4–6 realistic risks. Examples: content not feature-complete by milestone 2, 
demo build exposes full-game content (ungated), conversion blockers require 
design changes (not just polish), event submission deadline missed.

## Demo-Specific Constraints
Any constraints not captured elsewhere:
- Platform certification lead times (if console demo)
- Age rating requirements
- Store-specific demo length restrictions (Steam Next Fest: up to 2h is common)
- Press embargo dates

Flag any items marked [DECISION NEEDED] if the user's answers left key questions open.

[Include the following section only when EA_MODE = true:]

## Early Access Plan

### EA Overview
One paragraph: what Early Access means for this specific game, who it's for, and what state the game
will be in at EA launch versus 1.0. Be honest — EA players are buying access to an unfinished game.

### Pricing Strategy
Recommended EA price, planned 1.0 price, and the rationale for the discount level (or lack of one).
Flag if the pricing approach is unusual for the genre.

### Roadmap Commitments
What the developer is committing to deliver before 1.0:
- List each commitment as a measurable feature or content area (not vague promises)
- Flag any commitment that could be scope-risky (large feature, unknown implementation time)
- These commitments will be tracked as Required 1.0 Stories by `/demo-integrate --early-access`

### EA Exit Criteria
What "done" looks like for exiting Early Access:
- Target date or condition (e.g., "all roadmap commitments complete + 1 full QA pass")
- Content and feature completeness bar
- Any external conditions (minimum review count, wishlist target, etc.)

### EA-Specific Milestones
Add to the main Milestones section:
10. EA Publishing Requirements met (`/demo-gate [id] publishing` PASS)
11. EA Live (`/demo-gate [id] live` PASS)
```

Present the draft. Discuss and revise until approved.

---

## Phase 4: Producer Feasibility Sign-Off

**Review mode check:**
- `solo` → skip. Note: "PR-DEMO-PLAN skipped — Solo mode."
- `lean` → skip. Note: "PR-DEMO-PLAN skipped — Lean mode."
- `full` → spawn second producer pass as quality gate.

If `full`: spawn `producer` via Task with the draft plan and ask:
1. Is the milestone timeline achievable given current dev stage?
2. Is the effort estimate in the right order of magnitude?
3. Does the risk register cover the most likely failure modes?

Verdict: REALISTIC / CONCERNS / UNREALISTIC. Surface concerns before writing.

---

## Phase 5: Write Demo Plan

Ask: "May I write the demo production plan to `design/demo/demo-plan.md`?"

If yes, write the file, creating the directory if needed.

---

## Phase 6: Summary and Next Steps

```
Demo Production Plan — COMPLETE
================================
Output: design/demo/demo-plan.md
Target event: [event or window]
Go-live: [date or "TBD"]
Total milestones: [N]
Total estimated effort: [Xh]
Key risks: [top 2]

[DECISION NEEDED items, if any]

Next steps:
- /demo-scope — define exactly what content is included and locked in the demo
- /demo-build — once scope is locked and content is ready
- /demo-playtest — validate first impression and conversion after first build
[EA only:]
- /demo-gate [id] publishing — when demo is Released; validates EA store requirements before going live
- /demo-integrate --early-access — after EA launch; flags roadmap commitments as Required 1.0 stories
```

---

## Collaborative Protocol

- Never set a fixed deadline without the user confirming it (Phase 2, Question 2)
- Never invent content scope — derive only from game-concept.md and user answers
- Flag [DECISION NEEDED] rather than guessing on open production questions
- demo-plan is advisory, not blocking — /demo-scope can run without a plan in place
- Never write to `design/demo/` without explicit approval
