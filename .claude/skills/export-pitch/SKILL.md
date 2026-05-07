---
name: export-pitch
description: "Compiles project materials into a publisher-ready or investor-ready pitch document. Translates design documents into market-facing language: opportunity, differentiation, scope, and ask."
argument-hint: "<target> (e.g., 'publisher', 'investor', 'grant')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 0. Load Knowledge Base

Before writing anything, read `production/publishing/writing-lessons.md` if it exists.
Apply all rules, tone guidelines, and anti-patterns found there to this output.
Do not re-debate any decision marked as settled in the Game Design Decisions section.

---

## 1. Parse Argument & Set Target

If no argument provided, ask:

Use `AskUserQuestion`:
- "Who is this pitch for?"
  - Options: "Publisher", "Investor / VC", "Grant / Fund", "General (no specific target)"

Adjust tone and emphasis based on target:
- **Publisher** — focus on market fit, scope risk, and what support is needed
- **Investor** — focus on ROI, differentiation, and solo dev risk profile
- **Grant** — focus on cultural/creative value, feasibility, and milestone plan
- **General** — balanced across all of the above

---

## 2. Read Project Context

Read the following files:

- `design/gdd/game-concept.md` — required. Fail if missing:
  > "No game concept found. Run `/brainstorm` first."
- `design/gdd/systems-index.md` — load feature scope
- `production/milestones/*.md` — load timeline and current stage
- Glob `design/gdd/*.md` for any completed system GDDs

---

## 3. Confirm Before Writing

Present a summary:

> **Compiling pitch for: [target]**
> - Title: [game title]
> - Comparable titles found: [list from concept doc]
> - Scope tier: [from systems index or milestones]
> - Current stage: [from session state or milestones]

Use `AskUserQuestion`:
- "Anything to add before I compile? (e.g. funding amount, specific ask)"
  - Options: "No, compile now", "I want to specify the ask first",
    "I want to add a team bio section"

---

## 4. Write Pitch Document

Save to: `review/pitch-[target]-[YYYY-MM-DD].md`

Ask: "May I write the pitch document to `review/pitch-[target]-[YYYY-MM-DD].md`?"

Structure:

```markdown
# [Game Title] — [Target] Pitch
**Studio:** [name] | **Date:** [today] | **Platform:** [platform]

---

## Elevator Pitch
[2–3 sentences. What is this game and why will people buy it?]

## Market Opportunity
[Comparable titles with audience evidence. What gap does this fill?]

## Core Loop
[What the player does in one session. Simple and concrete.]

## Unique Selling Point
[One clear differentiator. Not a feature list — one thing.]

## Target Audience
[Who buys this, where they are, what they already play.]

## Monetization
[How the game makes money.]

## Scope & Timeline
[Current stage → milestone plan → estimated ship window.]

## Team
[Solo dev profile. Relevant experience. Shipped titles if any.]

## The Ask
[What you want: funding amount / QA support / marketing / distribution.]
```

---

## 5. Rules for Writing

- Publisher/investor language only — no MDA terms, no internal jargon
- Every market claim must reference a comparable title
- Be honest about solo dev scope — underselling risk destroys credibility
- No superlatives: never "revolutionary", "unique", "unlike anything"
- Length: tight. Pitch readers skim. Make every section earn its place.

---

## 6. Humanize Writing Pass

Apply `/humanize-writing` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table in the export — keep the file clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 7. Confirm and Summarize

After writing:

> **Pitch document saved to:** `review/pitch-[target]-[YYYY-MM-DD].md`
> - Target: [publisher / investor / grant]
> - Comparables used: [list]
> - The Ask: [one line summary]
