# Agent Test Spec: publishing-manager

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-06-08

## Agent Summary

Domain: Entire public-facing game lifecycle — publishing roadmap creation and maintenance, phase auditing, community strategy, content pipeline coordination, press/influencer relations, wishlist strategy. Runs a publishing pipeline in parallel with development.

Does NOT own: game design decisions (`game-designer`), production code (any programmer agent), launch date decisions (`producer` + `technical-director` combined).

**Domain**: `production/publishing/` — roadmap, community status, content calendar  
**Escalates to**: `producer` (direct report)  
**Delegates content execution to**: export skills (`export-devlog`, `export-social`, `export-steam-page`, etc.)  
**Coordinates with**: `community-manager`, `game-designer`, `release-manager`

---

## Static Assertions (Structural)

- [ ] `description:` present and strategy-focused (references publishing roadmap, phase auditing, community)
- [ ] Model tier is Opus (strategic multi-document synthesis)
- [ ] `skills:` list includes core publishing execution skills
- [ ] Agent explicitly states it does not make game design or code decisions
- [ ] Agent reads current dev stage before making publishing recommendations

---

## Test Cases

### Case 1: Phase audit — publishing readiness check

**Input:** "We just hit our vertical slice milestone. What publishing work should I be doing?"

**Expected behavior:**
- Reads `production/milestones/` and `production/session-state/active.md` for current dev stage
- Reads `production/publishing/publishing-roadmap.md` if it exists; offers to create it if not
- Cross-references vertical slice stage against the publishing phase map
- Reports with priority markers:
  - 🔴 Overdue: Steam Coming Soon page (should have been done at MVP Prototype)
  - 🟡 Unlocked now: Steam Next Fest research, influencer target list, trailer brief, press kit
  - 🟢 Upcoming: Press outreach (unlocks at Alpha)
- Does NOT auto-execute tasks — presents findings and asks which to tackle first

### Case 2: Out-of-domain redirect — game design question

**Input:** "Should we add multiplayer to improve our market positioning?"

**Expected behavior:**
- Does NOT make the game design decision
- Provides market positioning context (multiplayer vs. single-player market size, comparable titles)
- Explicitly escalates the design decision to `game-designer` and `producer`
- Frames input as: "Here's the market context. The design decision belongs to game-designer."

### Case 3: Publishing roadmap creation

**Input:** "We don't have a publishing roadmap yet. Create one."

**Expected behavior:**
- Reads current dev stage from production files before drafting
- Produces roadmap in the specified format: Phase Status table + Overdue/Unlocked/Upcoming/Completed sections
- Roadmap reflects actual current stage — does not mark tasks complete without evidence
- Shows draft to user before writing. Asks "May I write this to production/publishing/publishing-roadmap.md?"
- After writing, offers to tackle the first unlocked task

### Case 4: Press outreach timing advice

**Input:** "I want to send press pitches to game journalists now." (Dev stage: early alpha, 8 months from launch)

**Expected behavior:**
- Advises that outreach 8 months out is generally too early — journalists forget
- Explains optimal timing (3–6 months pre-launch for personalized pitches)
- Offers a staged approach: build the press target list now, execute outreach when timing is right
- Does NOT refuse the request — offers a constructive alternative

### Case 5: Content calendar coordination

**Input:** Context: "Community platforms: Twitter/X and Steam. Dev stage: Alpha. Current wishlist count: 180." Request: "Plan this month's content calendar."

**Expected behavior:**
- References all context: Twitter/X + Steam platforms, alpha stage, 180 wishlists
- Produces a concrete content calendar with platform-specific post types for the month
- Flags 180 wishlists as likely below Steam Next Fest thresholds — prioritizes wishlist-push content
- Delegates specific content drafting to export skills (`export-devlog`, `export-social`)
- Asks "May I write this to production/publishing/content-calendar.md?" before writing

---

## Protocol Compliance

- [ ] Reads current dev stage before making recommendations — does not assume stage
- [ ] Uses the publishing phase map to frame all recommendations
- [ ] Uses 🔴/🟡/🟢 markers for overdue/unlocked/upcoming tasks
- [ ] Escalates game design decisions to `game-designer`
- [ ] Escalates launch date decisions to `producer` + `technical-director`
- [ ] Delegates content drafting to export skills — does not author content inline
- [ ] Uses "May I write" before writing roadmap or calendar files

---

## Coverage Notes

- Case 1 tests the core phase audit loop (primary workflow)
- Case 4 tests strategic timing judgment vs. blind execution
- Case 5 verifies the agent connects wishlist metrics to tactical priorities
- No gate IDs assigned
