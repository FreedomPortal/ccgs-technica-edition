---
name: export-review
description: "Compiles current project state into a clean external review document for outside consultants, advisors, or collaborators. Synthesizes GDD, systems index, and sprint status into a single briefing file."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, TodoWrite
---

When this skill is invoked:

## 0. Load Knowledge Base

Before writing anything, read `production/publishing/writing-lessons.md` if it exists.
Apply all rules, tone guidelines, and anti-patterns found there to this output.
Do not re-debate any decision marked as settled in the Game Design Decisions section.

---

## 1. Read Project Context

Read the following files before writing anything:

- `design/gdd/game-concept.md` — required. Fail if missing:
  > "No game concept found. Run `/brainstorm` first."
- `design/gdd/systems-index.md` — required. Fail if missing:
  > "No systems index found. Run `/map-systems` first."
- `production/session-state/active.md` — optional, load if exists
- `production/milestones/*.md` — optional, load most recent if exists

Glob `design/gdd/*.md` to find any completed system GDDs.

---

## 2. Confirm Scope With User

Present a brief summary of what was found:

> **Ready to compile review document**
> - Game: [title from concept]
> - Systems found: [count] designed, [count] undesigned
> - Latest sprint: [name or "not found"]
> - Open questions detected: [count or "none"]

Use `AskUserQuestion`:
- "Anything specific you want the reviewer to focus on?"
  - Options: "No, compile everything", "Flag open design questions only",
    "Focus on core loop and systems status"

---

## 3. Write Review Document

Save to: `review/review-export-[YYYY-MM-DD].md`

Ask: "May I write the review document to `review/review-export-[YYYY-MM-DD].md`?"

Structure:

```markdown
# Project Review — [Game Title]
**Studio:** [studio name] | **Date:** [today] | **Stage:** [current milestone]

---

## 1. Project Snapshot
[1 paragraph. Studio, game title, genre, platform, current dev stage.
Write for someone who knows games but knows nothing about this project.]

## 2. Core Concept & Loop
[What the player does. What they feel. What makes it different.
No internal jargon. No MDA terminology. Player-facing language only.]

## 3. Systems Status
[Table: System name | Status | Notes]
[Status values: Designed / In Progress / Undesigned]

## 4. Current Focus
[What's being built right now and why it's the right priority.]

## 5. Open Questions
[Each unresolved design decision, flagged with ❓]
[If none: "No open questions at this time."]
```

---

## 4. Rules for Writing

- Write for an external reader — no agent names, no tool names, no internal shorthand
- Design and experience language only — no technical implementation details
- Each section must be self-contained and readable without prior context
- Do not editorialize or recommend — compile and clarify only
- Flag open questions clearly with ❓

---

## 5. Humanize Writing Pass

Apply `/humanize-writing` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table in the export — keep the file clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 6. Confirm and Summarize

After writing, confirm:

> **Review document saved to:** `review/review-export-[YYYY-MM-DD].md`
> - Sections: Project Snapshot, Core Concept, Systems Status, Current Focus, Open Questions
> - Open questions captured: [count]
>
> Ready to share with your external consultant.
