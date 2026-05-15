---
name: log-lesson
description: "Encodes a lesson learned from external feedback into the project knowledge base. Run this after receiving critique from consultants, playtesters, press, or any external reviewer to permanently improve agent output quality. Lessons are stored in production/publishing/writing-lessons.md and automatically applied by all export skills."
argument-hint: "<source> (e.g., 'press-kit-review', 'playtest-1', 'publisher-feedback')"
user-invocable: true
allowed-tools: Read, Write, Edit, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Parse Source Argument

If no argument provided, ask:
> "What is the source of this feedback?"
> (e.g., 'external-consultant', 'press-kit-review', 'playtest-1', 'publisher-meeting')

Use this as the source label in the lesson entry.

---

## 2. Load Existing Knowledge Base

Read `production/publishing/writing-lessons.md` if it exists.
This prevents duplicate lessons and shows what's already encoded.

If it doesn't exist, note that it will be created.

---

## 3. Gather the Lesson

Ask in conversation (open-ended — do not use AskUserQuestion here):
> "Describe the feedback in your own words.
> What was the problem, and what's the correct approach going forward?"

Listen to the user's description, then ask:

Use `AskUserQuestion`:
- "What category does this lesson belong to?"
  - Options: "Writing & Tone", "Marketing & Positioning",
    "Game Design Decision", "Anti-Pattern (what this game is NOT)"

---

## 4. Format the Lesson

Structure the lesson as:

```markdown
### [YYYY-MM-DD] — [source]
**Context:** [what was being written or designed when this came up]
**Problem:** [what was wrong with the original approach]
**Rule:** [the principle to apply going forward — one clear sentence]
**Example:**
❌ [the wrong version]
✅ [the correct version]
```

Show the formatted lesson to the user before writing:
> "Here's how I'll encode this lesson. Does this capture it correctly?"

Use `AskUserQuestion`:
- Options: "Yes, write it", "Let me adjust the wording first",
  "Add another lesson from the same session"

---

## 5. Write to Knowledge Base

If `production/publishing/writing-lessons.md` does not exist, create it
with full structure (see template below).

If it exists, append the lesson to the correct section.

Ask: "May I append this lesson to
`production/publishing/writing-lessons.md`?"

After writing, confirm:
> "Lesson encoded. All export skills will apply this rule going forward."

Verdict: COMPLETE

---

## 6. Offer to Log More

Use `AskUserQuestion`:
- "Any more lessons from this feedback session?"
  - Options: "Yes, log another", "No, that's all for now"

---

## Knowledge Base Template (for first creation)

```markdown
# Project Knowledge Base — [Game Title]
**Studio:** [studio] | **Last updated:** [date]

This file encodes lessons learned from external review, playtesting,
press feedback, and consultant sessions. All export skills read this
file before generating output. Add to it with `/log-lesson`.

---

## How to Read This File

Each lesson follows this format:
- **Context** — what was being worked on when the lesson emerged
- **Problem** — what was wrong with the original approach
- **Rule** — the principle to apply going forward
- **Example** — wrong version vs. correct version

---

## Writing & Tone Rules

*Rules for how copy, descriptions, and player-facing text should be written.*

[lessons appended here]

---

## Marketing & Positioning Rules

*Rules for how the game should be positioned, hooked, and described to press/players.*

[lessons appended here]

---

## Game Design Decisions

*Settled design decisions that agents should not re-debate or contradict.*

[lessons appended here]

---

## Anti-Patterns

*Things this game is NOT — protect the vision from drift.*

[lessons appended here]
```
