---
name: demo-polish
description: "Demo-specific polish pass focused on first-impression quality, onboarding clarity, and end-state CTA conversion — not general content polish. Scoped to the first 2 minutes, the onboarding sequence, and the wishlist/buy prompt. Run after /demo-feedback clears P1 blockers and before the final /demo-build."
argument-hint: "(no argument) [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Read Prerequisites

Read the following if they exist:
- `design/demo/demo-scope.md` — included content, playthrough flow, end state, acceptance criteria
- `design/gdd/game-concept.md` — pillars, player fantasy, core loop
- `production/qa/playtests/demo-conversion-summary.md` — per-session conversion data

Glob `production/qa/playtests/demo-playtest-*.md` to find playtest reports.
Glob `production/qa/playtests/demo-feedback-*.md` to find feedback synthesis documents.

If `design/demo/demo-scope.md` does not exist:
> "`design/demo/demo-scope.md` not found. Run `/demo-scope` first."
Stop.

If no playtest reports found:
> "No demo playtest reports found. Run `/demo-playtest` at least once before a
> polish pass — polish should target known friction points, not assumed ones."
Use `AskUserQuestion`:
- Prompt: "Proceed without playtest data?"
- Options:
  - `Yes — I'll identify polish targets manually`
  - `No — I'll run /demo-playtest first`

If No: stop.

---

## Phase 2: Extract Polish Targets

If playtest reports exist, read the most recent feedback synthesis (latest `demo-feedback-*.md`)
or the individual reports if no synthesis exists.

Extract all items categorized as:
- **Polish items** (from playtest categorization)
- **Onboarding failures** (mechanics not understood without help)
- Any **conversion blocker** already flagged as "polish-resolvable" (not design-level)

Ask user to confirm which polish targets to include. Use `AskUserQuestion` if the list
is non-trivial:
- Prompt: "I found [N] polish targets from playtest data. Which areas should this pass focus on?"
- Options (check all that apply — ask as multi-select if supported, else list):
  - First 2 minutes / launch experience
  - Onboarding and tutorial clarity
  - Core gameplay feel and responsiveness
  - Demo end state / wishlist CTA
  - Visual and audio polish
  - UI / HUD clarity
  - All of the above

Store the confirmed focus areas.

---

## Phase 3: Generate Demo Polish Checklist

Spawn `game-designer` via Task with this prompt:

```
Generate a demo polish checklist for a game demo.

Demo scope (what is in the demo, the playthrough flow, and the end state):
[paste design/demo/demo-scope.md]

Game pillars and player fantasy:
[paste relevant sections from game-concept.md]

Polish targets from playtest data:
[paste extracted items from Phase 2]

User-confirmed focus areas: [list from Phase 2]

Generate a prioritized demo polish checklist. Demo polish is NOT general content polish —
every item must directly improve one of these demo-specific metrics:
1. First-impression clarity (does the player immediately understand what kind of game this is?)
2. Onboarding completeness (can a first-time player understand and enjoy the demo without help?)
3. Completion rate (do players reach the end of the demo, or do they drop off?)
4. Conversion intent (after finishing, do players want to wishlist or buy?)

## Demo Polish Checklist

For each item:
- **Area**: [First impression / Onboarding / Gameplay feel / End state CTA / Visual / Audio / UI]
- **Item**: [Short description of what to polish]
- **Why it matters for demos**: [1 sentence — link to the metric it improves]
- **Source**: [Playtest data / Design spec / Pillar alignment]
- **Effort**: [Low / Medium / High]
- **Priority**: [P1 = do before any public release / P2 = do before public but after P1 / P3 = nice to have]

## First 2 Minutes Focus
The first 2 minutes are the most critical window of the demo experience. Every demo player
is a first-time player. Identify specific polish items that affect the first 2 minutes only:
- Opening screen / title card quality
- First input / first action clarity
- First feedback loop (does the player know if they did something right?)
- Audio and visual first impression (is the game immediately appealing?)

## Onboarding Sequence
List the specific UI elements, tooltips, tutorial moments, or environmental cues that
need polish to improve onboarding clarity.

## End State / CTA Polish
The wishlist or buy CTA is the demo's final conversion moment. List specific items:
- Does the end screen appear at the right moment (not too abrupt, not too late)?
- Is the CTA copy clear and compelling?
- Are the store links functional and tested?
- Does the screen visually stand out from the gameplay?

## Out of Scope for This Pass
List any items that are NOT in scope for demo polish:
- New content (add to main game backlog)
- Core design changes (requires /propagate-design-change, not polish)
- Full-game content improvements (defer to main sprint polish)
```

Present the checklist to the user. Discuss and revise.

---

## Phase 4: Team Polish Delegation

**Review mode check for scope:**
- All modes → spawn `team-polish`, but scope the prompt to demo-specific items only.

Spawn `team-polish` via Task with this prompt:

```
Execute a demo-specific polish pass. This is NOT general content polish.

The polish pass is scoped exclusively to these demo metrics:
1. First-impression quality (first 2 minutes)
2. Onboarding clarity (tutorial, tooltips, first-time player guidance)
3. Completion rate (friction that causes players to stop before the demo end)
4. End state / CTA conversion (the wishlist or buy prompt at the demo's end)

Demo scope (for context on what is in the demo):
[paste design/demo/demo-scope.md]

Demo polish checklist (your target list):
[paste Phase 3 checklist]

Rules for this pass:
- P1 items must be addressed before this task is complete
- P2 items should be addressed if effort permits
- P3 items are optional — flag which were completed
- Do NOT polish content that is not in the demo scope
- Do NOT make design changes — flag design-level issues as [DESIGN CHANGE NEEDED]
  and leave them for /propagate-design-change
- If a UX flow needs redesign (not just polish), flag it for /ux-review instead

Report back:
- P1 items: DONE / BLOCKED (with blocker description) / DEFERRED (with reason)
- P2 items: DONE / DEFERRED
- P3 items: DONE / SKIPPED
- Any [DESIGN CHANGE NEEDED] flags
- Any [UX REVIEW NEEDED] flags
```

If `team-polish` returns BLOCKED items: surface them and ask the user how to proceed.

---

## Phase 5: Creative Director Sign-Off

**Review mode check:**
- `solo` → skip. Note: "CD-DEMO-POLISH skipped — Solo mode."
- `lean` → skip. Note: "CD-DEMO-POLISH skipped — Lean mode."
- `full` → spawn as normal.

Spawn `creative-director` via Task:

```
Review the completed demo polish pass for alignment with game pillars and conversion intent.

Game pillars and player fantasy:
[paste from game-concept.md]

Demo scope:
[paste from demo-scope.md]

Polish items completed:
[paste team-polish results]

Assess:
1. Does the polished first-2-minutes experience clearly communicate the game's identity?
2. Does the end state / CTA feel like a natural and compelling conclusion to the demo?
3. Are there any polish items that conflict with the pillars or feel off-brand?

Verdict: APPROVED / MINOR CONCERNS / REJECTED
One paragraph of reasoning.
```

If MINOR CONCERNS: surface them and let the user decide whether to address before final build.
If REJECTED: do not proceed to final build. Surface specific issues to resolve.

---

## Phase 6: Write Polish Record

Ask: "May I write the demo polish record to `production/qa/demo-polish-[date].md`?"

If yes, write the file with:
- Summary of focus areas
- P1/P2/P3 completion status
- Any BLOCKED items and resolutions
- Any DESIGN CHANGE NEEDED / UX REVIEW NEEDED flags
- Creative director verdict (if full mode)

---

## Phase 7: Summary and Next Steps

```
Demo Polish Pass — COMPLETE
============================
Output: production/qa/demo-polish-[date].md
P1 items: [X done / Y blocked]
P2 items: [X done / Y deferred]
P3 items: [X done / Y skipped]
Creative director: [APPROVED / CONCERNS / REJECTED / skipped]

[If any DESIGN CHANGE NEEDED flags:]
⚠️ Design-level issues flagged — run /propagate-design-change on:
[list items]

[If any UX REVIEW NEEDED flags:]
⚠️ UX flow issues flagged — run /ux-review on:
[list items]

Next steps:
- /demo-build — export the final demo build with all polish applied
- Smoke-test on a clean machine before distribution
- [If Next Fest:] Submit via Steamworks → Demos section
```

---

## Collaborative Protocol

- Demo polish is scoped to conversion-critical areas only — do not expand to full-game polish
- Never make design changes in a polish pass — flag for /propagate-design-change
- Never polish content that is not in the demo scope (design/demo/demo-scope.md)
- Flag [DESIGN CHANGE NEEDED] and [UX REVIEW NEEDED] rather than attempting scope expansion
- Never write to `production/qa/` without explicit approval
