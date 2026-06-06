---
name: market-research
description: "Competitive intelligence for an indie game concept. Produces comp title analysis, pricing benchmarks, audience sizing, platform fit, and release timing guidance. Output feeds /marketing-plan and /press-outreach. Requires a game concept (run /brainstorm first)."
argument-hint: "(no argument needed — reads game concept automatically)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Task, WebSearch
model: sonnet
---

When this skill is invoked:

## Phase 1: Read Current State

Read the following files before asking anything:

- `design/gdd/game-concept.md` — required. Extracts: title, genre, one-line hook, core fantasy, target audience, platforms, scope, comparable titles mentioned in brainstorm.
- `production/publishing/market-research.md` — load if exists (update mode, not recreate).
- `production/publishing/publishing-roadmap.md` — read if exists (current dev stage context).

If no game concept exists, stop:
> "No game concept found. Run `/brainstorm` first — market research requires
> a defined genre, target audience, and core hook."

---

## Phase 2: Determine Mode

If `production/publishing/market-research.md` already exists:
> "A market research file already exists. What would you like to do?"

Use `AskUserQuestion`:
- Options: "Update with new comps or data", "Re-run full analysis (archive old)", "Just review the existing file"

If "Just review": read and summarize the existing file, then stop.
If "Update": proceed to Phase 3, carrying forward existing comps and noting what's being refreshed.
If fresh: proceed to Phase 3.

---

## Phase 3: Gather Research Parameters

Use `AskUserQuestion` (batched — use tabs form):

Tab **"Depth"** — "How thorough should the comp analysis be?"
- Options: `Quick (3–5 comps, pricing + audience only)` / `Standard (6–8 comps, full competitive breakdown)` / `Deep (10+ comps, include niche and adjacent genres)`

Tab **"Focus"** — "What's your primary research question?"
- Options: `Pricing — what should I charge?` / `Audience — who are my players and where do they live?` / `Platform fit — which storefronts should I target?` / `All of the above`

Tab **"Known comps"** — "Do you have specific comp titles to include?"
- Options: `No — generate from concept` / `Yes — I'll add them after the analysis` / `Yes — let me list them now`

If "Yes — let me list them now": follow up with a free-text prompt to capture the user's list. Pass these to the agent as seed comps.

---

## Phase 4: Spawn Publishing Manager

Read `design/gdd/game-concept.md` to extract game title, genre, one-line hook, target audience, platforms, and scope. Collect any user-provided comp titles from Phase 3.

Spawn `publishing-manager` via Task:

```
You are the publishing manager for [GAME TITLE], a [GENRE] game.
One-line hook: [HOOK]
Target audience: [AUDIENCE]
Target platforms: [PLATFORMS]
Scope: [SCOPE — e.g., solo dev, 12–18 month project]
User-provided comp titles: [LIST OR "none provided"]
Research depth: [DEPTH FROM PHASE 3]
Research focus: [FOCUS FROM PHASE 3]

Produce a structured competitive intelligence report. Use WebSearch to verify
current pricing, recent releases, and platform availability where possible.

**⚠️ Data freshness warning**: Your training data has a cutoff (August 2025).
Steam revenue, player counts, and review scores change continuously. All
figures must be framed as estimates — instruct the developer to verify with
SteamDB, Gamalytic, or Steam charts before making any business decisions.
Flag any comp title released after mid-2025 as "post-cutoff — verify".

## 1. Comparable Title Analysis

Identify [DEPTH] comparable titles. Prioritize commercial comparables (games
that sold to a similar audience at a similar price point) over genre clones.

For each comp title, provide:
- Title, developer, launch year, platforms
- Price at launch (and current price if discounted)
- Steam review score and count (or equivalent on other platforms) — note if estimated
- Estimated audience size (very small / small / mid / large — with rationale)
- What this game did well that this concept should learn from
- What this game did poorly or left underserved — potential gap to exploit
- Relevance: why this is a true commercial comp (not just genre similarity)

Present as a structured table followed by per-title notes.

## 2. Pricing Benchmark

Based on the comps and current market:
- What is the price band for this genre and scope? (min / median / max)
- What price point would you recommend for [GAME TITLE] at launch, and why?
- Is Early Access pricing appropriate for this concept? What discount from full price?
- Any regional pricing considerations (e.g., SEA, Eastern Europe, Brazil) worth flagging?
- Discount calendar: what are typical discount depths and timing for this genre?

## 3. Audience Profile

- Primary demographic: who plays these games? (age range, platform preference, play style)
- Where does this audience live online?
  - Subreddits (name specific ones, with approx subscriber count)
  - Discord communities (name specific ones)
  - YouTube/Twitch creators who cover these games (name 5–8 specific names)
  - Other platforms (itch.io communities, specific forums)
- What does this audience care about? (features they upvote, complaints they repeat)
- Red flags: any community sensitivities or expectations this concept might trigger?

## 4. Platform Fit

For each platform the developer is targeting ([PLATFORMS]):
- How well does this genre perform on this platform? (strong / moderate / weak)
- Is this platform under- or over-saturated with this genre?
- Any platform-specific audience quirks (e.g., Steam users dislike always-online; mobile users churn fast)?
- Recommendation: prioritize / include / deprioritize — with rationale

Also flag any platform the developer has NOT mentioned that may be a strong fit.

## 5. Release Timing

- Are there seasonal windows that consistently perform well for this genre?
- Are there windows to avoid (major AAA release windows, gaming events that dominate press)?
- Any upcoming platform events worth targeting (Steam Next Fest, Steam Sales, Nintendo Direct period)?
- Given the scope estimate of [SCOPE], what's the earliest realistic launch window and which seasonal slot does it fall in?

## 6. Market Gap Analysis

Based on the comps, what is underserved in this genre that [GAME TITLE] could own?
- Name the gap specifically (not "make it better" — name what's missing)
- Is there evidence in player reviews or community posts that this gap is felt?
- How does [HOOK] position the game to fill that gap?

## 7. Solo Developer Scope Filter

Flag which findings are most actionable for a solo or small-team developer.
Recommend a minimum viable market intelligence slice — the 3–5 insights with
the highest decision-making impact before any more development happens.

Report the full analysis. Do not write any game code.
```

After the agent completes, review the output. If any comp titles appear fabricated or implausible, note that they need manual verification before the file is written.

---

## Phase 5: Write Market Research File

Present a summary of the agent's findings to the user.

Ask: "May I write the market research report to `production/publishing/market-research.md`?"

Wait for confirmation before writing. Create `production/publishing/` if it does not exist.

```markdown
# Market Research — [Game Title]
**Last updated:** [date]
**Research depth:** [depth]
**Research focus:** [focus]

> ⚠️ **Data freshness**: All figures are estimates as of [date]. Verify pricing,
> review counts, and player numbers with SteamDB, Gamalytic, or Steam charts
> before making business decisions. Comps marked "post-cutoff" should be
> verified manually.

---

## Comparable Titles

| Title | Dev | Year | Platform | Price | Reviews | Audience | Relevance |
|-------|-----|------|----------|-------|---------|----------|-----------|
[rows from agent output]

### Per-Title Notes

[expanded notes per comp]

---

## Pricing Benchmark

**Recommended launch price:** [price] — [rationale]
**Price band for genre:** [min] – [max]
**Early Access pricing:** [recommendation]
**Discount guidance:** [calendar notes]

---

## Audience Profile

### Who They Are
[demographic summary]

### Where They Live Online
| Platform | Community | Size | Notes |
|----------|-----------|------|-------|
[subreddits, discords, creators]

### What They Care About
[key audience values and red flags]

---

## Platform Fit

| Platform | Genre Fit | Saturation | Recommendation |
|----------|-----------|-----------|----------------|
[per-platform rows]

---

## Release Timing

**Best windows:** [seasons/events]
**Windows to avoid:** [dates/events]
**Earliest realistic launch:** [window based on scope]

---

## Market Gap

**The gap:** [specific underserved need]
**Evidence:** [community signals or review patterns]
**How this game fills it:** [connection to hook]

---

## Priority Insights (Solo Dev Slice)

1. [highest-impact insight]
2. [second insight]
3. [third insight]
4. [fourth insight]
5. [fifth insight]

---

## Sources to Verify

- SteamDB: https://www.steamdb.info/
- Gamalytic: https://gamalytic.com/
- Steam charts: https://store.steampowered.com/charts/
```

---

## Phase 6: Humanize Writing Pass

Apply `/refine-copy` to the saved file in-place. Edit the file with the humanized output. Do not include the Changes table — keep the file clean. This pass runs automatically; no user approval needed.

---

## Phase 7: Summary

After writing, output:

```
Market Research — [Game Title]
==============================
Comps analyzed:   [N]
Recommended price: [price]
Primary audience:  [2-line description]
Key market gap:    [one sentence]
Output:           production/publishing/market-research.md

⚠️  Verify all figures with SteamDB and Gamalytic before acting on them.

Next steps:
- Run /marketing-plan to map these insights to your publishing timeline
- Run /press-outreach to build a contact list targeting this audience
- Update this file as the game evolves and new comps release

Verdict: COMPLETE
```

---

## Collaborative Protocol

- Never write files without explicit approval in Phase 5
- Always surface the data-freshness warning — LLM comp data is a starting list, not ground truth
- If the user's concept is still vague (no clear genre or hook), flag it and recommend finishing `/brainstorm` before re-running
- If comp titles the user provided are obscure or potentially misremembered, note that they will be included as-listed but should be verified
