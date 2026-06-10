---
name: monetization-design
description: "Design the revenue model for the game: pricing strategy (premium, F2P, DLC), post-launch revenue streams, and player trust alignment. Flags pay-to-win and dark pattern risks explicitly. Produces design/monetization/monetization-plan.md."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Detect Current State

Read:
- `design/gdd/game-concept.md` — game title, genre, target audience, platforms
- `production/publishing/publishing-roadmap.md` — current stage, target launch window
- `design/monetization/monetization-plan.md` — load if exists (update vs. create)
- `design/gdd/economy.md` — in-game economy design if it exists

If no game concept exists, stop:
> "No game concept found. Run `/brainstorm` first — monetization design depends
> on knowing the genre, target audience, and platform."

---

## Phase 2: Determine Mode

If `design/monetization/monetization-plan.md` already exists:
> "A monetization plan already exists. What would you like to do?"

Use `AskUserQuestion`:
- Options: "Review and update existing", "Add a new revenue stream", "Start fresh (archive the old one)"

If no plan exists: proceed to Phase 3.

---

## Phase 3: Choose Revenue Model

Use `AskUserQuestion`:
- Prompt: "What is your primary revenue model?"
- Options:
  - `Buy-once (premium)` — one-time purchase price; no ongoing revenue mechanics
  - `Buy-once + DLC` — base price + optional paid content expansions
  - `Free-to-play + cosmetics` — free base game; revenue from cosmetic items only (no gameplay advantage)
  - `Free-to-play + premium currency` — free base game; premium currency for gameplay or cosmetic items

Record the choice — it determines which ethical guardrails apply and which downstream agents are involved.

---

## Phase 4: Spawn Economy Designer and Publishing Manager

Read `design/gdd/game-concept.md` to extract game title, genre, target audience, and
platforms before spawning. Spawn both agents via Task simultaneously.

**Agent 1 — economy-designer:**

```
You are the economy designer for [GAME TITLE], a [GENRE] game targeting [PLATFORMS].
Target audience: [AUDIENCE]
Chosen revenue model: [MODEL FROM PHASE 3]

Design the monetization plan. Produce:

1. Pricing Strategy
   - Recommended launch price (justify against comparable titles by genre + platform)
   - Regional pricing considerations (Steam pricing tiers, key markets)
   - Rationale: why this price fits the game's perceived value

2. Post-Launch Revenue Streams (based on chosen model)
   For each stream:
   - Type: DLC / Expansion / Cosmetic Pack / Season Pass / etc.
   - Timing: when post-launch (3 months / 6 months / 12 months)
   - Scope: what is included
   - Price: suggested price and justification

3. Ethical Guardrails — flag each of the following if present in the proposed model:
   - Pay-to-win: gameplay advantage purchasable with real money — ALWAYS flag as HIGH RISK
   - Loot boxes / gacha with real money: randomized paid rewards — flag risk level and
     jurisdiction concerns (Belgium and Netherlands have enacted bans; other markets reviewing)
   - FOMO mechanics: artificial scarcity or time pressure tied to purchases — flag as MEDIUM RISK
   - Dark patterns: misleading pricing, confusing currency conversions, hidden costs — flag
     as HIGH RISK and name the specific pattern
   - Predatory targeting: mechanics designed to exploit high-spending players — flag as HIGH RISK

   For each flagged item: explain why it is a risk (player trust, legal, platform policy)
   and suggest an alternative that achieves the revenue goal without the risk.

4. Player Trust Alignment
   - What the player gets at the base price (no ambiguity)
   - Clear statement of what is and is not purchasable post-launch
   - Recommended store page transparency statement

5. Platform Considerations
   - Steam: refund policy implications (2 hours / 14 days)
   - Any platform-specific monetization restrictions for the chosen platforms

Format the output as a structured plan document. Do not write any game code.
```

**Agent 2 — publishing-manager:**

```
You are the publishing manager for [GAME TITLE], a [GENRE] game targeting [PLATFORMS].
Revenue model: [MODEL FROM PHASE 3]
Target audience: [AUDIENCE]

Review the revenue model from a publishing and market positioning perspective:

1. Market Fit: Does this pricing model match what players in [GENRE] expect?
   Name 2–3 comparable titles and their monetization approach.

2. Timing Risk: Are there timing risks (e.g., launching F2P in a market currently
   saturated with F2P titles in this genre)?

3. Community Perception: How is this monetization model typically received by the
   [GENRE] player community? What signals make players trust or distrust it?

4. Recommended Messaging: How should the developer communicate the monetization
   model on the Steam page and in community posts to maximize trust?

Report in under 400 words. Do not write any game code.
```

After both agents complete, present both outputs to the user for review before writing anything.

---

## Phase 5: Write Plan

Ask: "May I write the monetization plan to `design/monetization/monetization-plan.md`?"

Wait for confirmation before writing.

Create `design/monetization/` if it does not exist. Write the file with this structure:

```markdown
# Monetization Plan — [Game Title]
**Last updated:** [date]
**Revenue model:** [chosen model]

---

## Pricing Strategy

[From economy-designer output]

---

## Post-Launch Revenue Streams

[From economy-designer output]

---

## Ethical Guardrails

[Flags from economy-designer — HIGH RISK items listed first]

> **Policy:** This game will not include [list any models explicitly ruled out].

---

## Player Trust Alignment

[From economy-designer output]

---

## Market Positioning

[From publishing-manager output]

---

## Platform Considerations

[From economy-designer output]
```

---

## Phase 6: Summary

After writing, output:

```
Monetization Plan — [Game Title]
==================================
Model:           [revenue model]
Launch price:    [recommended price]
Revenue streams: [N] post-launch streams planned
Risks flagged:   [N] (HIGH: X, MEDIUM: Y)
Output:          design/monetization/monetization-plan.md

Next steps:
1. Add the monetization model to the Steam store page draft (/publish-steam-page)
2. Run /live-ops-plan to align post-launch content cadence with revenue streams
3. Run /balance-check to verify the in-game economy aligns with the monetization model

Verdict: COMPLETE — monetization plan designed.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 5 requires explicit approval before any write
- Both economy-designer and publishing-manager produce input — always present both for review before writing
- **Ethical guardrails are non-negotiable**: any HIGH RISK flag must be visible in the output document, even if the developer chooses to proceed — document the risk and the developer's decision
- Do not recommend loot box or gacha mechanics without explicitly flagging the jurisdiction legal risks (Belgium and Netherlands bans; other markets under active review)
- If the developer's concept has no monetization (e.g., jam game or free project), document "No monetization" as a deliberate decision with a reason
