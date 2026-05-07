---
name: press-outreach
description: "Build a media contact list and draft outreach templates for journalists, YouTubers, and streamers. Creates production/publishing/press-contacts.md with contact tracking. Advises on timing relative to launch. Coordinates: publishing-manager + community-manager."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Detect Current State

Read:
- `design/gdd/game-concept.md` — game title, genre, target audience, platforms
- `production/publishing/publishing-roadmap.md` — current dev stage and target launch window
- `production/publishing/press-contacts.md` — load if exists (update vs. create)
- Any presskit files: Glob `production/publishing/presskit*` and `production/publishing/*press-kit*`

If no game concept exists, stop:
> "No game concept found. Run `/brainstorm` first — press outreach requires
> knowing the game's genre, target audience, and hook."

Note if no press kit exists:
> "No press kit found. Journalists expect a press kit before outreach begins.
> Consider running `/export-review` first to generate a press kit package, or
> prepare key materials manually (capsule art, fact sheet, screenshots, trailer link)."

This is advisory — do not stop if the press kit is missing; the user may be building
the contact list in advance.

---

## Phase 2: Determine Mode

If `production/publishing/press-contacts.md` already exists:
> "A press contacts file already exists. What would you like to do?"

Use `AskUserQuestion`:
- Options: "Add new contacts", "Update contact statuses", "Review outreach strategy", "Start fresh"

If no file exists: proceed to Phase 3.

---

## Phase 3: Understand Outreach Context

Use `AskUserQuestion`:
- Prompt: "What is the primary goal of this outreach?"
- Options:
  - `Review coverage` — get journalists to review the game at or near launch
  - `Wishlist push` — get coverage while in development to drive Steam wishlists
  - `Content creator coverage` — YouTubers and streamers playing the game (let's plays, first look)
  - `All of the above` — comprehensive media strategy

Use `AskUserQuestion`:
- Prompt: "How far are you from launch?"
- Options:
  - `6+ months` — early outreach; focus on awareness and wishlists
  - `2–3 months` — mid-cycle; send review key requests and schedule embargoes
  - `Under 1 month` — final push; personalized pitches, day-one review coordination
  - `Already launched` — post-launch coverage for visibility boost

Record both answers — they determine contact tier priorities and template tone.

---

## Phase 4: Spawn Publishing Manager and Community Manager

Read `design/gdd/game-concept.md` to extract game title, genre, one-line hook, and target
audience before spawning. Spawn both agents via Task simultaneously.

**Agent 1 — publishing-manager:**

```
You are the publishing manager for [GAME TITLE], a [GENRE] game.
One-line hook: [HOOK from game-concept.md]
Target audience: [AUDIENCE]
Outreach goal: [GOAL FROM PHASE 3]
Time to launch: [TIMING FROM PHASE 3]

Produce a press outreach plan. Include:

1. Target Contact Tiers (prioritized list)
   For each tier, describe the profile:
   - Tier 1: High-impact — major indie game press, large YouTube/Twitch streamers in this genre
   - Tier 2: Mid-tier — genre-focused blogs, mid-size YouTubers, Twitch streamers (10k–100k)
   - Tier 3: Community — Reddit communities, Discord communities, smaller niche creators

   For each tier: describe the profile, expected effort to reach, and expected conversion
   rate (realistic for an unknown indie game).

2. Specific Outlet/Creator Suggestions
   Name 10–15 specific outlets, journalists, YouTubers, or streamers who cover [GENRE]
   games. For each: name, outlet/channel, platform, why they are a good fit for this game.
   Note: these are suggestions — the developer must verify contact details independently.

3. Outreach Email Templates
   Write 3 templates:
   a) Cold pitch — first contact, journalist has never heard of this game
   b) Review key offer — sending a free key with a specific ask for coverage
   c) Follow-up — polite follow-up 1 week after no response

   Each template: subject line + body (under 200 words). Use [PLACEHOLDER] for values the
   developer fills in. Tone: professional but warm; do not grovel.

4. Timing Advice
   Based on time-to-launch ([TIMING]), recommend:
   - When to send initial outreach
   - When to send review keys (if applicable)
   - Embargo date recommendation (if applicable)
   - When NOT to send (e.g., major gaming events where inboxes are saturated)

5. Solo Developer Scope Filter
   Flag which parts of this plan a solo developer can realistically execute alone vs. what
   requires sustained time investment. Recommend a minimum viable outreach slice (top 5–10
   contacts to prioritize).

Report the full plan. Do not write any game code.
```

**Agent 2 — community-manager:**

```
You are the community manager for [GAME TITLE], a [GENRE] game.
Outreach goal: [GOAL FROM PHASE 3]
Time to launch: [TIMING FROM PHASE 3]

Advise on community-driven press amplification:

1. Reddit strategy: which subreddits to post in when coverage lands (to amplify reach)
2. Discord strategy: which indie game Discord servers are appropriate for announcements
3. Timing alignment: how community posts should be timed to amplify press coverage

Report in under 300 words. Do not write any game code.
```

After both agents complete, present the contact suggestions and templates to the user for
review before writing anything.

---

## Phase 5: Write Press Contacts File

Ask: "May I write the press contacts file to `production/publishing/press-contacts.md`?"

Wait for confirmation before writing.

Create `production/publishing/` if it does not exist. Write the file with this structure:

```markdown
# Press Contacts — [Game Title]
**Last updated:** [date]
**Outreach goal:** [goal]
**Launch timing:** [timing]

---

## Outreach Templates

### Cold Pitch
**Subject:** [template subject]

[template body]

---

### Review Key Offer
**Subject:** [template subject]

[template body]

---

### Follow-Up
**Subject:** [template subject]

[template body]

---

## Timing Guide

[Timing advice from agent output]

---

## Contact List

| Name | Outlet / Channel | Platform | Tier | Status | Notes |
|------|-----------------|----------|------|--------|-------|
[One row per suggested contact — Status = "not contacted"]

---

## Amplification Strategy

[Community amplification advice from community-manager]

---

## Minimum Viable Outreach (Solo Dev Slice)

[Top 5–10 contacts flagged by agent as highest priority]
```

---

## Phase 6: Humanize Writing Pass

Apply `/humanize-writing` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table in the export — keep the file clean. This pass runs automatically; no user approval needed before the next step.

---

## Phase 7: Summary

After writing, output:

```
Press Outreach — [Game Title]
==============================
Goal:          [outreach goal]
Launch timing: [timing]
Contacts:      [N] suggested ([T1] Tier 1, [T2] Tier 2, [T3] Tier 3)
Templates:     3 (cold pitch, review key offer, follow-up)
Output:        production/publishing/press-contacts.md

Next steps:
1. Verify contact details independently — do not rely on agent-suggested names alone
2. Prepare press kit assets before sending outreach (/export-review)
3. Send Tier 1 outreach [N] weeks before launch per the timing guide above
4. Update the Status column in press-contacts.md as you send and receive responses

Verdict: COMPLETE — press outreach plan created.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 5 requires explicit approval before any write
- Contact names suggested by the publishing-manager are starting points — always note that the developer must independently verify current email addresses, submission forms, and contact preferences before sending outreach
- Do not suggest bought contact lists, automated mass email tools, or any outreach that could be classified as spam
- If no press kit exists, always surface the advisory note from Phase 1 — outreach without a press kit has a materially lower response rate
- If time-to-launch is "Already launched": adjust tone — coverage for a launched game focuses on long-tail visibility, discount events, and update milestones, not review embargoes
