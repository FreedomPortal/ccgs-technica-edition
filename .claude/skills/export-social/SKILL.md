---
name: export-social
description: "Generates a batch of social media posts from recent development activity. Produces platform-native drafts for Twitter/X, Reddit, and TikTok/Instagram. Use after a sprint, prototype milestone, or design decision worth sharing."
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

## 1. Read Recent Activity

Read the following files:

- `production/session-state/active.md` — what was just built or decided
- `design/gdd/game-concept.md` — core hooks and fantasy for marketing angles
- `review/devlog-*.md` — latest devlog if it exists (mine for post material)

---

## 2. Identify What's Shareable

From the context, identify:
- **Progress moment** — something concrete that was built or reached
- **Design insight** — a decision made and the thinking behind it
- **Player hook** — the fantasy or feeling the game promises

Use `AskUserQuestion`:
- "What's the main thing you want to communicate this week?"
  - Options: "Progress update (built something)", "Design process (made a decision)",
    "Game reveal / awareness (sell the fantasy)", "All three"

---

## 3. Write Post Batch

Save to: `review/social-posts-[YYYY-MM-DD].md`

Ask: "May I write the social post batch to `review/social-posts-[YYYY-MM-DD].md`?"

Structure:

```markdown
# Social Post Batch — [Date]

---

## Twitter / X

**[Progress Update]** (max 280 chars)
[Concrete progress with a hook. Flag with [NEEDS: screenshot/GIF] if visual helps.]

**[Design Insight]** (max 280 chars)
[One decision + reasoning. Appeals to dev community.]

**[Player Hook]** (max 280 chars)
[Sell the fantasy, not the feature. No jargon.]

---

## Reddit

**Post title:** [r/indiegaming or r/gamedev]
[150–300 words. Give value to the reader — don't just ask for attention.
Show something real, explain the thinking, invite discussion.]

---

## TikTok / Instagram Caption

[2–3 sentences. Energetic. Written for someone seeing this game for the first time.]
**Tags:** [5 specific, relevant hashtags — no generic spam]

[NEEDS: video / GIF of [describe what footage would work best]]
```

---

## 4. Rules for Writing

- Never fabricate assets — flag every post that needs a visual
- Twitter posts must be self-contained — no cliffhanger threads unless content warrants
- Reddit must give value first, promotion second
- Hashtags: specific and relevant — no #gaming #indiedev spam
- Tone per platform: Twitter = sharp, Reddit = honest/detailed, TikTok = energetic
- Do not promise features that aren't built or scoped

---

## 5. Humanize Writing Pass

Apply `/humanize-writing` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table in the export — keep the file clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 6. Confirm and Summarize

After writing:

> **Social post batch saved to:** `review/social-posts-[YYYY-MM-DD].md`
> - Posts written: [count] across [count] platforms
> - Visuals needed: [count] flagged with [NEEDS]
