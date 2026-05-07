---
name: export-crowdfunding
description: "Compiles project materials into a crowdfunding campaign document for Kickstarter or similar platforms. Produces campaign page copy, reward tier suggestions, and risk disclosures."
argument-hint: "<platform> (e.g., 'kickstarter', 'indiegogo')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 0. Load Knowledge Base

Before writing anything, read `production/publishing/writing-lessons.md` if it exists.
Apply all rules, tone guidelines, and anti-patterns found there to this output.
Do not re-debate any decision marked as settled in the Game Design Decisions section.

---

## 1. Parse Argument & Validate Readiness

If no platform argument, default to Kickstarter format.

Read `design/gdd/game-concept.md` — required. Fail if missing:
> "No game concept found. Run `/brainstorm` first."

Warn if no prototype or vertical slice exists:
> "⚠️ No prototype milestone detected. Crowdfunding before a playable build
> significantly reduces backer confidence. Consider running `/milestone-review`
> first to assess readiness."

Use `AskUserQuestion`:
- "Do you have a playable build to show backers?"
  - Options: "Yes, vertical slice is ready", "Partial prototype only",
    "No build yet — planning ahead"

---

## 2. Read Project Context

Read:
- `design/gdd/game-concept.md` — concept, fantasy, comparables
- `design/gdd/systems-index.md` — scope tiers for funding unlock levels
- `production/milestones/*.md` — what exists now vs. what funding enables

---

## 3. Confirm Funding Goal

Use `AskUserQuestion`:
- "Do you have a funding target in mind?"
  - Options: "Not yet — help me estimate", "Under $5,000", "$5,000–$20,000",
    "Over $20,000"

If "help me estimate": note that the skill cannot calculate this reliably
without cost data — recommend consulting `/estimate` with the producer agent first.

---

## 4. Write Campaign Document

Save to: `review/crowdfunding-[platform]-[YYYY-MM-DD].md`

Ask: "May I write the campaign document to `review/crowdfunding-[platform]-[YYYY-MM-DD].md`?"

Structure:

```markdown
# [Game Title] — Crowdfunding Campaign
**Platform:** [Kickstarter / Indiegogo] | **Date:** [today]

---

## Campaign Headline
[One line. The promise of the game. Must earn the click.]

## The Hook
[First 3 sentences of the campaign page. Must earn the scroll.
Write for a stranger who has never heard of this game.]

## What Is This Game
[Core fantasy and loop in plain language. No jargon. No MDA terms.
Write as if explaining to a friend who plays games but not this genre.]

## Why This Game Needs to Exist
[The gap this fills. What players are missing right now.]

## What's Already Built
[Honest proof of concept. Screenshots / GIF descriptions if applicable.
Flag with [NEEDS: asset description] wherever visuals are required.]

## What Your Funding Enables
[Specific scope unlocks — be honest about what base funding covers
vs. what stretch goals enable. Never promise what solo dev can't deliver.]

## Reward Tiers
| Tier | Price | Name | What You Get |
|------|-------|------|-------------|
| 1 | $[X] | [Name] | [Digital reward — copy of game at launch] |
| 2 | $[X] | [Name] | [Game + digital artbook / soundtrack] |
| 3 | $[X] | [Name] | [Above + name in credits] |
| 4 | $[X] | [Name] | [Above + early access / beta] |
| 5 | $[X] | [Name] | [Above + design input session] |

## About the Developer
[Who you are, why you're making this, relevant experience.
First person. Honest. Not a CV.]

## Risks & Challenges
[Required on Kickstarter. Be honest — it builds trust, not doubt.
Address: solo dev scope, art pipeline, timeline estimates.]

## Stretch Goals *(if applicable)*
[Only include if scope is genuinely expandable without scope creep risk.]
```

---

## 5. Rules for Writing

- Backer language only — players, not industry professionals
- Every feature claim must be backed by what already exists or is firmly scoped
- Reward tiers: digital only unless physical rewards are explicitly budgeted
- Risks section: required and honest — do not minimize or skip
- Tone: passionate, personal, direct — a human asking humans for support

---

## 6. Humanize Writing Pass

Apply `/humanize-writing` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table in the export — keep the file clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 7. Confirm and Summarize

After writing:

> **Campaign document saved to:** `review/crowdfunding-[platform]-[YYYY-MM-DD].md`
> - Platform: [Kickstarter / Indiegogo]
> - Reward tiers: [count]
> - Visuals flagged as needed: [count]
> - Risks section: included
>
> ⚠️ Before launching: validate reward tier deliverability with `/scope-check`.
