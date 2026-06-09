---
name: tutorial-design
description: Design the tutorial sequence for a game — mechanic audit, teaching order, scaffolding strategy (diegetic/contextual/forced/scaffolded), skip/replay rules, and a high-level tutorial state machine sketch. Spawns ux-designer (flow lead) and game-designer (mechanic sequencing) as coordinated subagents. Output: design/tutorial/tutorial-design.md
model: sonnet
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

# /tutorial-design

Produces a structured tutorial design document before any tutorial implementation begins.

**Stage placement:** Pre-Production (planning) or Vertical Slice (if tutorial is part of the VS core loop). Must exist before `/dev-story` writes any tutorial implementation story.

**Output:** `design/tutorial/tutorial-design.md`

**Agents:** `ux-designer` leads (owns the output); `game-designer` consulted for mechanic classification and sequencing.

---

## Phase 1 — Mechanic Audit

Spawn `game-designer` subagent via Task with the following brief:

> Read all GDDs in `design/gdd/`. Produce a flat list of every mechanic the player must learn to play the game. For each mechanic, classify:
> - **Complexity**: Simple (1 input → 1 output) / Compound (multiple inputs, conditional outcomes) / Systemic (interacts with other mechanics)
> - **Teachability**: Can the player discover it through play, or must it be explicitly taught?
> - **Dependency**: Which other mechanics must be understood first?
> - **Critical path**: Is understanding this mechanic required to progress, or optional?
>
> Return a table: Mechanic | Complexity | Teachability | Dependencies | Critical Path

Collect output. Present mechanic table to user before proceeding.

---

## Phase 2 — Teaching Sequence

Using the `game-designer` mechanic audit, spawn `ux-designer` subagent via Task:

> Given this mechanic table: [table from Phase 1]
>
> Produce a teaching sequence — the order in which mechanics should be introduced to a new player. Apply these rules:
> 1. Dependencies must be taught before dependents
> 2. Simple mechanics before compound before systemic
> 3. Critical-path mechanics before optional ones
> 4. No more than 2 new mechanics per tutorial segment
>
> Output: ordered list of tutorial segments, each segment containing: segment name, mechanics introduced, prerequisite segments, estimated duration in minutes.

Collect output. Present sequence to user. Ask: "Does this teaching order match your intent? [Y/E to edit/N to restart]"

If edit: user specifies changes; revise order.

---

## Phase 3 — Scaffolding Strategy

For each mechanic in the teaching sequence, classify the teaching method:

| Method | When to use |
|--------|-------------|
| **Diegetic** | Mechanic can be demonstrated through environment, NPC action, or world state — no UI needed |
| **Contextual hint** | Pop-up or tooltip triggered on first encounter — mechanic is discoverable but benefits from a nudge |
| **Forced tutorial moment** | Mechanic is too complex or critical to leave to discovery — player must engage before progressing |
| **Scaffolded challenge** | Isolated test scenario before combining with other mechanics — used for compound/systemic mechanics |

Spawn `ux-designer` subagent for this phase:

> For each mechanic in the teaching sequence: [sequence from Phase 2]
> Recommend a scaffolding method from the table. Justify each choice.
> Flag any "forced tutorial moment" candidates — these are high-friction; recommend only when genuinely necessary.
> Output: Mechanic | Method | Justification | UI/world element needed

Present to user. Allow edits.

---

## Phase 4 — Skip/Replay Design

Define the accessibility and replayability rules:

**Skip conditions** — when can a player skip a tutorial segment?
- Typical: player demonstrates competence (completes mechanic correctly N times) → skip offered
- Or: returning player flag (save data exists) → tutorial skippable from main menu

**Replay access** — where can players re-trigger tutorials?
- In-game help menu (preferred) vs. settings screen vs. not available

**Accessibility fallback** — always-available reference:
- Help text strings (fed to `/player-docs help-text`) vs. in-game codex vs. external manual link

Spawn `ux-designer` subagent:

> Design skip and replay rules for the tutorial sequence: [sequence]
> Consider: returning players, players who accidentally skip, players who need re-explanation.
> Output: Skip condition per segment | Replay trigger | Accessibility fallback location

Present to user. Confirm.

---

## Phase 5 — Tutorial State Machine Sketch

High-level states only — not a full implementation spec. Scope for `/dev-story` to implement.

```
pre-tutorial
  → active: [mechanic-1-segment]
    → active: [mechanic-2-segment]
      → ...
        → complete
  → skipped (if skip condition met)
```

Flag which states require **persistence** (tutorial progress survives session quit/crash):
- Typically: all states after the first mechanic introduction

Spawn `ux-designer`:

> Sketch the tutorial state machine using the sequence and scaffolding from Phases 2–3.
> Include: state names, transitions, entry/exit conditions, persistence requirements.
> Keep it high-level — this is a design sketch, not an implementation spec.

Present state machine. Note: this sketch becomes the implementation contract for `/dev-story tutorial`.

---

## Phase 6 — Write

Ask: "May I write `design/tutorial/tutorial-design.md`? [Y/N]"

On approval, create `design/tutorial/` if needed, then write using the template at `.claude/docs/templates/tutorial-design.md`.

After write:

```
✅ Tutorial design written: design/tutorial/tutorial-design.md

  Mechanics covered: [N]
  Tutorial segments: [N]
  Estimated total tutorial time: [N] minutes
  Forced tutorial moments: [N] (flag if > 3 — high friction risk)

Next steps:
  - Run /dev-story tutorial to implement from this spec
  - Run /player-docs help-text to generate in-game help strings from this doc
  - Run /ux-review design/tutorial/tutorial-design.md to validate flow
```
