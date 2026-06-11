# Skill Spec: /community-plan

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/community-plan` creates or updates the community strategy for the game. It reads the game concept, existing community status, and publishing roadmap, then presents a recommended platform stack (Reddit, Twitter/X, itch.io, TikTok/YouTube Shorts) with per-platform content strategies and posting cadences. It supports four modes: strategy review, metrics update, content planning for the current week, and new platform setup. Output files are `production/publishing/community-status.md` (updated) and `production/publishing/content-calendar.md` (created or updated). The skill applies a humanize writing pass before concluding with a COMPLETE verdict and handoff to `/publish-social` or `/publish-devlog`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/community-plan` is a publishing utility with no director-tier gate. It is a downstream consumer of `/marketing-plan` and an upstream producer for `/publish-social` and `/publish-devlog`. No gate verdict is issued or required.

---

## Test Cases

### Case 1: Happy Path — First-Run Platform Setup
**Fixture**:
- `design/gdd/game-concept.md` exists with genre, audience, comparable titles
- `production/publishing/community-status.md` does not exist
- `production/publishing/publishing-roadmap.md` exists with current dev stage

**Expected behavior**:
1. Reads all three source files without error
2. Detects no existing community setup; skips mode-selection question
3. Presents recommended platform stack for the game's genre
4. Asks which platforms to set up (Tier 1, Tier 1+2, or custom)
5. Generates per-platform content strategy for selected platforms
6. Presents content calendar draft
7. Asks `"May I write the content calendar to production/publishing/content-calendar.md?"`
8. Writes content calendar; updates or creates `community-status.md`
9. Runs humanize pass on saved files
10. Outputs COMPLETE verdict with next content action and export skill handoffs

**Assertions**:
- [ ] Mode-selection question not fired (no existing setup)
- [ ] Platform stack recommendation references game genre/audience from concept
- [ ] `"May I write"` approval gate for content-calendar write
- [ ] `content-calendar.md` contains "This Sprint" table and Content Ideas Backlog
- [ ] COMPLETE verdict present
- [ ] Handoff mentions `/publish-social` or `/publish-devlog`

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Game Concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- No other publishing files present

**Expected behavior**:
1. Phase 1 reads attempt for `game-concept.md` returns nothing
2. Skill cannot determine genre, audience, or comparable titles for recommendations
3. Should surface a blocking condition or produce a degraded output noting missing context
4. No platform strategy is written without game concept data

**Assertions**:
- [ ] Skill does not silently produce a generic strategy without game concept
- [ ] User is informed that game concept is missing or recommendations are unconstrained
- [ ] No files written without meaningful input data
- [ ] Either halts with advisory or clearly flags all recommendations as unconstrained placeholders

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Metrics Update
**Fixture**:
- All three source files exist
- `community-status.md` has active platforms listed
- User selects "Update platform status/metrics" when mode question fires

**Expected behavior**:
1. Detects existing community setup; presents four-option mode question
2. User selects metrics update mode
3. Skill prompts for wishlist count, follower count, devlog views, best-performing post, weekly streak
4. Collects values in plain text (one question per field)
5. Asks `"May I update the metrics in production/publishing/community-status.md?"` before writing
6. Writes updated metrics into the Current Metrics section of `community-status.md`
7. Does not recreate `content-calendar.md` in this mode
8. Outputs COMPLETE verdict

**Assertions**:
- [ ] Mode-selection question fires with all four options
- [ ] Metrics collected as individual prompts (not batched into one question)
- [ ] `"May I update the metrics"` approval gate fires
- [ ] Only `community-status.md` is written (not content-calendar)
- [ ] COMPLETE verdict present

**Case Verdict**: PASS

---

### Case 4: Edge Case — Custom Platform Selection
**Fixture**:
- `design/gdd/game-concept.md` exists
- No existing community setup
- User selects "Custom selection" for platform stack

**Expected behavior**:
1. Standard platform stack recommendation presented
2. User selects custom; skill prompts for specific platform list
3. Content strategy sections generated only for user-specified platforms
4. Account setup checklist covers only selected platforms
5. Content calendar reflects only active platforms
6. Approval gate fires before writing

**Assertions**:
- [ ] Content strategy not generated for unselected platforms
- [ ] Account setup checklist scoped to selected platforms only
- [ ] Approval gate fires before writes
- [ ] No hardcoded assumption that Reddit + Twitter/X are always included

**Case Verdict**: PASS

---

### Case 5: Protocol — Approval Gate Before File Writes
**Fixture**:
- All source files exist, no existing community plan
- Skill has drafted platform strategy and content calendar

**Expected behavior**:
1. Skill presents content calendar draft to user before writing
2. Asks `"May I write the content calendar to production/publishing/content-calendar.md?"`
3. For metrics update path: asks `"May I update the metrics in production/publishing/community-status.md?"`
4. No file is written without explicit per-file approval

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
- [ ] No auto-write

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The humanize writing pass (Phase 7, `/refine-copy` in-place) runs automatically per SKILL.md without user approval — this is a runtime-only behavior and cannot be verified statically.
- Platform-specific subreddit name substitution (e.g., `r/[GENRE_SUBREDDIT]`) requires game concept data at runtime; static analysis can only confirm the placeholder convention is used.
- The "Plan content for this week" and "Set up a new platform" modes are described but not fully detailed in the SKILL.md beyond the mode selection step — runtime behavior for these paths is partially underdefined and warrants a follow-up skill-improve pass.
- `community-status.md` write approval is described explicitly in the metrics update path (Phase 2a) but not separately called out for the first-run creation path — testers should confirm approval fires in both paths.
