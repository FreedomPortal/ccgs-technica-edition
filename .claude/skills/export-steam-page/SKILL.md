---
name: export-steam-page
description: "Compiles project materials into a Steam store page document — short description, long description, key features, and tags. Use when preparing the Steam Coming Soon page or full launch page."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 0. Load Knowledge Base

Before writing anything, read `production/publishing/writing-lessons.md` if it exists.
Apply all rules, tone guidelines, and anti-patterns found there to this output.
Do not re-debate any decision marked as settled in the Game Design Decisions section.

---

## 1. Read Project Context

Read the following files:

- `design/gdd/game-concept.md` — required. Fail if missing:
  > "No game concept found. Run `/brainstorm` first."
- `design/gdd/systems-index.md` — feature set for bullet points
- Any art direction or aesthetic notes in design docs

---

## 2. Confirm Page Type

Use `AskUserQuestion`:
- "What stage is this Steam page for?"
  - Options: "Coming Soon page (pre-launch awareness)",
    "Early Access launch", "Full launch (V1.0)"

- "Do you have a confirmed price point?"
  - Options: "Not yet", "Free to play", "Under $10", "$10–$20", "Over $20"

---

## 3. Write Steam Page Document

Save to: `review/steam-page-[YYYY-MM-DD].md`

Ask: "May I write the Steam page document to `review/steam-page-[YYYY-MM-DD].md`?"

Structure:

```markdown
# Steam Page — [Game Title]
**Page type:** [Coming Soon / Early Access / Full Launch] | **Date:** [today]

---

## Game Title
[Final title as it appears on Steam]

## Tagline
[One line under the title. Max 30 words. The promise of the game.]

## Short Description
[Max 160 characters. Appears in search results. Must work as plain text with no image.]

## Long Description
[150–300 words. Lead with player fantasy, follow with features.
Use Steam BB formatting:]

[h2][Core Fantasy 1 Heading][/h2]
[Body paragraph...]

[h2][Core Fantasy 2 Heading][/h2]
[Body paragraph...]

[h2]Key Features[/h2]
[list]
[*] [Player benefit, not system name]
[*] [Player benefit, not system name]
[*] [Player benefit, not system name]
[*] [Player benefit, not system name]
[*] [Player benefit, not system name]
[/list]

---

## Steam Tags (priority order)
[15 tags, most relevant first]

---

## Content Flags
- Early Access: [Yes / No]
- Content warnings: [list or "none"]

---

## Visual Requirements
[List all visuals still needed for this page with [NEEDS] flags]
- Header capsule (460×215): [NEEDS]
- Vertical capsule (374×448): [NEEDS]
- Screenshots (min 5): [NEEDS]
- Trailer: [NEEDS]
```

---

## 4. Rules for Writing

- Short description must work without any image — plain text in search results
- Long description leads with player fantasy — never open with a feature list
- Feature bullets are player-facing: "Build a robot from 100+ parts"
  not "Modular part system"
- No superlatives without evidence: never "ultimate", "revolutionary", "unlike anything"
- Steam tags must reflect actual genre and mechanic — do not keyword-stuff
- Flag every missing asset with `[NEEDS]`

---

## 5. Humanize Writing Pass

Apply `/humanize-writing` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table in the export — keep the file clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 6. Confirm and Summarize

After writing:

> **Steam page document saved to:** `review/steam-page-[YYYY-MM-DD].md`
> - Page type: [Coming Soon / Early Access / Launch]
> - Visuals flagged as needed: [count]
> - Tags generated: 15
>
> Note: Steam requires a Coming Soon page to be live for at least 2 weeks before launch.
