---
name: community-plan
description: "Creates or updates the community strategy for the game. Defines platform choices, posting cadence, content types, and growth tactics tailored to the game's genre and audience. Coordinates with export-social and export-devlog for content execution."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Read Current State

Read:
- `design/gdd/game-concept.md` — genre, target audience, comparable titles
- `production/publishing/community-status.md` — existing platform status
- `production/publishing/publishing-roadmap.md` — current dev stage

---

## 2. Determine Mode

If `community-status.md` exists with active platforms:
> "You have an existing community setup. Do you want to review strategy,
> update platform status, or plan this week's content?"

Use `AskUserQuestion`:
- Options: "Review and update strategy", "Update platform status/metrics",
  "Plan content for this week", "Set up a new platform"

If no community setup exists: proceed to platform setup.

### 2a. Metrics Update (if "Update platform status/metrics" selected)

Prompt the user for current values (plain text — one question per field):
- Store wishlist count (enter 0 if Coming Soon page not live yet)
- Social media follower count (Twitter/X, etc.)
- Devlog views (average per post, or total if only 1 post)
- Best-performing post: platform, brief description or link, engagement number
  (upvotes / likes / views)
- Weekly posting streak: how many consecutive weeks with ≥1 post published?

Write the collected values into the Current Metrics section of
`community-status.md`. Ask: "May I update the metrics in
`production/publishing/community-status.md`?" before writing.

---

## 3. Platform Setup (first run)

Present recommended stack based on game type. For a typical release on Steam/Desktop:

> **Recommended platform stack for [GAME TITLE]:**
>
> **Tier 1 — Start now (pre-production)**
> - Reddit — r/indiegaming, r/[GENRE_SUBREDDIT], r/gamedev
>   Post when you have something real to show. Quality over frequency.
> - Twitter/X — dev community + press. 2–3 posts/week during active dev.
>
> **Tier 2 — Start at MVP Prototype**
> - itch.io devlog — low effort, good SEO, indie community discovery
>
> **Tier 3 — Start at Vertical Slice**
> - TikTok/YouTube Shorts — only when you have gameplay footage worth showing
>
> **Not recommended (yet)**
> - Discord — too early without an existing audience
> - Facebook — often the wrong demographic for indie titles

Use `AskUserQuestion`:
- "Which platforms do you want to set up now?"
  - Options: "Reddit + Twitter/X (start Tier 1)",
    "Reddit + Twitter/X + itch.io (Tier 1 + 2)",
    "Custom selection"

---

## 4. Content Strategy Per Platform

For each selected platform, define:

**Reddit**
- Subreddits: r/indiegaming (player audience), r/[GENRE_SUBREDDIT] (genre audience),
  r/gamedev (dev community)
- Best post types: "I made a thing" with GIF/screenshot, devlog crosspost,
  design question that invites discussion
- Cadence: 1 post per major milestone (not weekly — quality over noise)
- Golden rule: Give value first. Show something real. Never just self-promote.

**Twitter/X**
- Content mix: 40% progress updates, 30% design insights, 30% player hooks
- Cadence: 2–3 posts per week during active dev, 1/week minimum
- Key accounts to follow/engage: other indie devs in similar genres,
  game journalists who cover [GAME GENRE]
- Use `/export-social` to generate post batches

**itch.io**
- Set up devlog page alongside or before Steam Coming Soon
- Cross-post devlogs from `/export-devlog`
- Lower audience than Steam but better long-term SEO
- Good for players who find games before they're on Steam

---

## 5. Content Calendar

Create or update `production/publishing/content-calendar.md`:

```markdown
# Content Calendar — [GAME TITLE]
Last updated: [date]

## This Sprint / Milestone: [name]

| Date | Platform | Content Type | Status | Export Skill |
|------|----------|-------------|--------|--------------|
| [date] | Twitter/X | Progress update | planned | /export-social |
| [date] | Reddit | Devlog crosspost | planned | /export-devlog |
| [date] | itch.io | Devlog | planned | /export-devlog |

## Content Ideas Backlog
(Things worth posting when the moment is right)
- [ ] First gameplay footage — TikTok + Twitter
- [ ] Major feature/UI reveal — Reddit r/indiegaming
- [ ] Technical design deep-dive — Reddit r/gamedev
- [ ] Main character or mechanic reveal — Twitter thread

## Evergreen Content (post anytime)
- Feature build timelapse
- Before/after: initial prototype → polished build
- "What I learned from a bad playtest"
```

Ask: "May I write the content calendar to
`production/publishing/content-calendar.md`?"


---

## 6. Account Setup Checklist
If platforms are not yet set up, output an action list:

```
=== ACCOUNT SETUP CHECKLIST ===

Reddit (no account needed to post — use personal or studio account)
  [ ] Decide: personal account vs. studio account (u/[STUDIO NAME])
  [ ] Subscribe: r/indiegaming, r/[GENRE_SUBREDDIT], r/gamedev
  [ ] Lurk for 1 week before first post — understand the community

Twitter/X
  [ ] Create: @[STUDIO NAME] (or @[GAME TITLE] — check availability)
  [ ] Bio: "[game tagline] | Solo dev | Making [GAME TITLE]"
  [ ] First 3 posts before going public: introduce yourself, show something real
  [ ] Follow: 20 indie devs in similar genres before first game post

itch.io
  [ ] Create developer page: [STUDIO NAME] (check availability)
  [ ] Set up devlog for [GAME TITLE]
  [ ] First devlog: "What is [GAME TITLE]?" — run /export-devlog 1
```  

---

## 7. Humanize Writing Pass

Apply `/humanize-writing` to any prose content in the saved files in-place. Edit files with the humanized output. Do not include the Changes table in the exports — keep files clean. This pass runs automatically; no user approval needed before the confirmation step.

---

## 8. Confirm and Summarize
After writing files:

> **Community plan updated.**
> Active platforms: [list]
> Content calendar: `production/publishing/content-calendar.md`
>
> Next content action: [most urgent item from calendar]
> Run `/export-social` or `/export-devlog` to produce content now.