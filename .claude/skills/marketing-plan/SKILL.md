---
name: marketing-plan
description: "Creates or updates the publishing roadmap for the project. Maps development milestones to publishing tasks with timing, priority, and status tracking. Run this once in pre-production, then update at each milestone. This is the foundation skill — run it before any other publishing skill."
argument-hint: "(no argument needed — reads current dev stage automatically)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Read Current State

Read the following files before asking anything:

- `design/gdd/game-concept.md` — required for game title, genre, platforms
- `production/milestones/*.md` — current dev stage
- `production/publishing/publishing-roadmap.md` — load if exists (update, don't recreate)

If no game concept exists, fail with:
> "No game concept found. Run `/brainstorm` first."

---

## 2. Determine Mode

If `publishing-roadmap.md` already exists:
> "A publishing roadmap already exists. Do you want to review and update it,
> or start fresh?"

Use `AskUserQuestion`:
- Options: "Review and update existing", "Start fresh (archive the old one)"

If no roadmap exists: proceed to create.

---

## 3. Establish Publishing Baseline

If creating fresh, gather positioning before writing the roadmap.

Use `AskUserQuestion` (batch):

- "What is the current development stage?"
  - Options: "Pre-Production (design only)", "MVP Prototype (first playable)",
    "Vertical Slice (core loop complete)", "Alpha", "Pre-Launch"

- "Do you have a target launch window?"
  - Options: "Not yet", "6–12 months", "12–18 months", "18+ months"

- "Which community platforms will you use?"
  - Options: "Reddit + Twitter/X + itch.io (recommended)",
    "Reddit + Twitter/X only", "Custom (I'll specify)"

---

## 4. Write Publishing Roadmap

Create `production/publishing/` directory if it doesn't exist.
Save to: `production/publishing/publishing-roadmap.md`

Ask: "May I write the publishing roadmap to
`production/publishing/publishing-roadmap.md`?"

Structure:

```markdown
# Publishing Roadmap — [Game Title]
**Studio:** [studio] | **Last updated:** [date]
**Current dev stage:** [stage] | **Target launch window:** [window]

---

## How to Read This Document

- 🔴 Overdue — window is closing or already missed
- 🟡 Unlocked — current dev stage makes this actionable now
- 🟢 Upcoming — prepare now, execute when milestone is reached
- ✅ Complete

---

## Phase 1 — Pre-Production: Positioning

| Task | Status | Notes |
|------|--------|-------|
| Define game hook (one-line pitch) | [status] | |
| Identify comparable titles + audiences | [status] | |
| Choose community platforms | [status] | |
| Create social accounts | [status] | |
| Draft press kit skeleton | [status] | |

## Phase 2 — MVP Prototype: First Public Signal

| Task | Status | Notes |
|------|--------|-------|
| Steam Coming Soon page live | [status] | Needs: capsule art, short description |
| Devlog #1 published | [status] | Run /export-devlog |
| Social accounts posting | [status] | |
| Wishlist baseline established | [status] | |

## Phase 3 — Vertical Slice: Community Building

| Task | Status | Notes |
|------|--------|-------|
| Steam Next Fest — research submission window | [status] | |
| Influencer target list (10–20 names) | [status] | |
| Trailer brief written | [status] | |
| Press kit complete (art + fact sheet) | [status] | |
| Weekly devlog cadence established | [status] | |

## Phase 4 — Alpha: Visibility Push

| Task | Status | Notes |
|------|--------|-------|
| Press outreach begins | [status] | |
| Demo or playtest build available | [status] | |
| Wishlist push campaign | [status] | |
| Steam page fully polished | [status] | Run /export-steam-page |

## Phase 5 — Pre-Launch (3–6 months out)

| Task | Status | Notes |
|------|--------|-------|
| Launch trailer produced | [status] | |
| Personalized press pitches sent | [status] | Run /export-pitch publisher |
| Review key plan finalized | [status] | |
| Launch day coordination doc written | [status] | |

## Phase 6 — Launch

| Task | Status | Notes |
|------|--------|-------|
| Day-one social blast | [status] | |
| Community active monitoring | [status] | |
| Review response plan active | [status] | |
| Discount calendar set | [status] | |

---

## Overdue Items 🔴
[auto-populated by /publish-check]

## Unlocked Now 🟡
[auto-populated by /publish-check]

## Completed ✅
[move items here as they're done]
```

---

## 5. Update or Create Community Status File

If `production/publishing/community-status.md` doesn't exist, create it:

```markdown
# Community Status — [Game Title]
Last updated: [date]

## Platform Accounts

| Platform | Handle | Status | Notes |
|----------|--------|--------|-------|
| Reddit | — | not set up | r/indiegaming, r/roguelikes, r/gamedev |
| Twitter/X | — | not set up | |
| itch.io | — | not set up | devlog page |

## Posting Cadence Target
- Reddit: 1–2 posts per milestone (quality over frequency)
- Twitter/X: 2–3 posts per week during active dev
- itch.io: 1 devlog per sprint or milestone

## Metrics to Track
- Steam wishlist count
- Reddit post engagement (upvotes, comments)
- Twitter/X follower count
- itch.io devlog views
```

---

## 6. Humanize Writing Pass

Apply `/humanize-writing` to any prose content in the saved files in-place. Edit files with the humanized output. Do not include the Changes table in the exports — keep files clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 7. Confirm and Summarize

After writing:

> **Publishing roadmap created at:**
> `production/publishing/publishing-roadmap.md`
>
> Current stage: [stage]
> Overdue tasks: [count] 🔴
> Tasks unlocked now: [count] 🟡
>
> Run `/publish-check` at any time to audit your current status.
> Run `/community-plan` to set up your community platforms.
