---
name: export-devlog
description: "Generates a developer blog post (devlog) from recent sprint activity. Use at the end of a sprint or milestone to document progress for a public dev blog, itch.io devlog, or Steam developer update."
argument-hint: "<devlog-number> (e.g., '3')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 0. Load Knowledge Base

Before writing anything, read `production/publishing/writing-lessons.md` if it exists.
Apply all rules, tone guidelines, and anti-patterns found there to this output.
Do not re-debate any decision marked as settled in the Game Design Decisions section.

---

## 1. Parse Argument

If a devlog number is provided, use it in the title: `Devlog #[N]`
If not provided, glob `production/publishing/devlog-*.md` to find the latest number and increment.

---

## 2. Read Recent Activity

Read the following files:

- `production/session-state/active.md` — what was built recently
- `production/milestones/*.md` — sprint completed and next sprint goal
- `design/gdd/` — any design decisions made this period
- Previous devlog if it exists: `production/publishing/devlog-*.md` (for continuity of tone)

---

## 3. Ask Tone and Platform

Use `AskUserQuestion`:
- "Where will this devlog be posted?"
  - Options: "Dev blog / Medium", "itch.io devlog", "Steam developer update",
    "All of the above (write for broadest audience)"

- "Tone preference?"
  - Options: "Honest and technical (dev community)", "Enthusiastic and accessible (player audience)", "Match my previous devlog"

---

## 4. Write Devlog

Save to: `production/publishing/devlog-[N]-[YYYY-MM-DD].md`

Ask: "May I write the devlog to `production/publishing/devlog-[N]-[YYYY-MM-DD].md`?"

Structure:

```markdown
# Devlog #[N]: [Specific thing you built — not generic]
*[Studio name] | [Date]*

---

## What I Built
[Concrete progress. Describe what exists now that didn't exist before.
Note: flag with [NEEDS: screenshot / GIF] wherever a visual would help.]

## A Problem I Solved
[One challenge and how you approached it. Shows craft and process.]

## A Decision I Made
[One design or scope decision and the reasoning behind it.]

## What's Next
[Next milestone focus. Creates anticipation without overpromising.]

---
*[Optional honest note — something that didn't go as planned. Builds authenticity.]*
```

---

## 5. Rules for Writing

- First person — this is a human developer's voice, not a press release
- Specific over vague — "I built the workshop drag-and-drop UI" not "I made progress"
- Show thinking, not just results — readers follow devlogs for the process
- Never oversell — honest struggle is more engaging than manufactured hype
- Length: 300–600 words. Devlog readers skim.
- Flag every place that benefits from a visual with `[NEEDS: screenshot / GIF / video]`

---

## 6. Humanize Writing Pass

Apply `/humanize-writing` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table in the export — keep the file clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 7. Confirm and Summarize

After writing:

> **Devlog saved to:** `production/publishing/devlog-[N]-[YYYY-MM-DD].md`
> - Visuals needed: [count] flagged with [NEEDS]
> - Estimated read time: ~[N] minutes
