---
name: player-docs
description: Generate player-facing documentation in three modes — manual (authoritative reference), guide (strategy tips for engaged players), help-text (in-game contextual strings catalogue). Invokes writer agent with type-specific prompts. Translates GDD design language into player language. Output paths vary by mode.
model: sonnet
argument-hint: "[manual|guide|help-text]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

# /player-docs

Generates player-facing documentation from existing GDDs, UX specs, and balance docs.

**Agent routing:**
- `manual` + `guide` → `writer` leads; `game-designer` consulted for accuracy check
- `help-text` → `writer` only; feeds back to `ux-designer` for placement decisions

**Stage placement:**
- `manual` + `help-text` → Polish (game is feature-complete; docs reflect final systems)
- `guide` → Release or Post-Launch (needs final balance before publishing)

---

## Phase 1 — Parse Mode

`$ARGUMENTS[0]` = `manual` | `guide` | `help-text`

If missing: `AskUserQuestion`:
- Prompt: "Which player document do you want to generate?"
- Options:
  - `[A] manual` — authoritative reference; controls, systems, FAQ
  - `[B] guide` — strategy tips for engaged players; advanced mechanics, builds
  - `[C] help-text` — in-game contextual help strings catalogue

---

## Phase 2 — Load Source Material

Read the following for all modes:
- All GDDs in `design/gdd/` — system rules, mechanic descriptions
- `docs/CONTEXT.md` — canonical terminology (use these terms, not GDD internal names)

Additional per mode:
- **manual**: UX spec (`design/ux/` or equivalent), HUD design doc, control layout docs
- **guide**: balance data (from balance GDD section or separate balance doc), `production/balance/` sim reports if available
- **help-text**: `design/tutorial/tutorial-design.md` (trigger contexts), UX spec (placement decisions)

Identify gaps: GDDs that are stubs, missing system descriptions, undefined mechanics. List them as "Source gaps — these sections will be incomplete." Do not stop; proceed with available material.

---

## Mode: manual

**Output:** `production/publishing/game-manual.md`

### Spawn `writer` subagent

Brief:

> You are writing the official player manual for [game title].
> Your reader: a confused new player who just started the game and needs to understand it.
> Your job: translate design language into player language.
> Rule: never write "the Economy System calculates payout via grade × base_rate" — write "better fights earn more parts."
>
> Sources: [list GDD files read]
> CONTEXT.md terms: [key terms]
>
> Write these sections in order, one at a time. Ask for approval before proceeding to the next.
>
> Structure:
> 1. Quick Start — get playing in under 1 page; core loop in plain language; one tip
> 2. Controls Reference — every input mapped; keyboard+mouse and gamepad if applicable
> 3. Game Systems — one section per major system; written for a confused player, not a designer
> 4. Win Conditions & Objectives — what the player is trying to do and why it matters
> 5. UI Reference — what each HUD element means, in plain language
> 6. Frequently Asked Questions — anticipate the 8 most common "wait, why did that happen?" moments
> 7. Credits & Support — where to report bugs, contact info (placeholder if not known)
>
> Standards:
> - Plain language only — no jargon without immediate definition
> - Second person ("you") throughout
> - Short paragraphs (3 sentences max)
> - Every mechanic described in terms of player action and outcome, not implementation

After each section is written, present to user for approval before writing to file.

**Write:** `production/publishing/game-manual.md` using the template at `.claude/docs/templates/game-manual.md`

---

## Mode: guide

**Output:** `production/publishing/strategy-guide.md`

### Spawn `game-designer` subagent first

Brief:

> Read: [combat GDD, balance GDD, any available balance-sim reports]
> Produce: a list of non-obvious advanced mechanics, dominant build archetypes (with reasoning), and common beginner mistakes. This is input for a strategy guide.
> Format: Mechanic | Why non-obvious | Strategic implication

Then spawn `writer` subagent with game-designer output:

> You are writing a strategy guide for [game title] for engaged players who have completed the basics.
> Your reader: someone who has played 2+ hours and wants to improve.
> Tone: conversational, confident, concrete. Use "you" throughout.
>
> Structure:
> 1. Getting Started Tips — 5–8 tips a new player wishes they'd known in hour 1
> 2. Core Loop Efficiency — how to progress faster; what to prioritize; what to ignore early
> 3. System Deep-Dives — one per major system; advanced mechanics not covered in the manual
> 4. Build Recommendations — [N] example configurations with reasoning; reference game-designer findings
> 5. Common Mistakes — the top mistakes that hurt progression; how to avoid each
> 6. Advanced Techniques — highest-skill mechanics; mastery ceiling content
>
> Rules:
> - Every tip must be specific and actionable — "upgrade attack first" not "focus on upgrades"
> - Every build recommendation must state *why* it works mechanically
> - No speculation — only document what the GDD + balance data supports

After each section, present to user for approval.

**Write:** `production/publishing/strategy-guide.md` using template at `.claude/docs/templates/strategy-guide.md`

---

## Mode: help-text

**Output:** `production/publishing/help-text.md`

### Spawn `writer` subagent

Brief:

> You are writing in-game contextual help strings for [game title].
> Your reader: a player in the middle of a session who glanced at a tooltip and has 2 seconds.
> Rules:
> - One sentence per string, maximum 80 characters
> - No jargon — if you must use a game term, define it in the same sentence
> - Active voice only
> - No "This is a..." or "The [UI element] shows..." — get to the point
>
> Sources: [tutorial design doc for trigger contexts, GDDs for mechanic descriptions]
>
> For each trigger context identified in design/tutorial/tutorial-design.md:
> Write a help string. Format the output as a table:
>
> | Trigger Context | Help String | Char Count | Max (80) |
> |----------------|-------------|------------|---------|
>
> Also write help strings for any UI element in the HUD design doc that has no tutorial coverage.
> Group by: Workshop / Arena / Menus / Inventory / Other.

**Write:** `production/publishing/help-text.md`

After write:

```
ℹ️  Note for ux-designer: help-text.md is now available at production/publishing/help-text.md.
Review for placement decisions — which strings appear on first encounter, which are always-accessible.
```

---

## Phase 3 — Post-Write Summary

```
✅ Player docs written: [output path]

Mode: [manual|guide|help-text]
Sections completed: [N]
Source gaps noted: [N] — see "Source gaps" section in output file

Next steps:
  [manual]    → Run /refine-copy to reduce AI writing patterns
              → Share with a non-designer reader for clarity check
  [guide]     → Re-run after final balance lock; values may change
              → Suitable for Steam Guides post after Release
  [help-text] → Share with ux-designer for placement review
              → Feed strings to localization pipeline via /localization-export

Verdict: COMPLETE — player documentation written.
```
