# Skill Spec: /publish-social

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/publish-social` generates a batch of social media posts from recent development activity. It reads `production/session-state/active.md`, `design/gdd/game-concept.md`, and any latest devlog, then identifies three shareable angles: a progress moment, a design insight, and a player hook. After asking what the user wants to communicate, it writes a dated Markdown file at `review/social-posts-[YYYY-MM-DD].md` containing three Twitter/X drafts (max 280 chars each), one Reddit post (150–300 words), and one TikTok/Instagram caption with five hashtags. Visual requirements are flagged with `[NEEDS]`. The file is refined in-place via `/refine-copy` before a COMPLETE verdict is issued.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: No director or gate-check agent is involved. The single gate is the inline `"May I write"` prompt in Phase 3 before file creation.

---

## Test Cases

### Case 1: Happy Path — All Three Communication Types
**Fixture**:
- `production/session-state/active.md` exists with a recent build milestone
- `design/gdd/game-concept.md` exists with core hooks
- A devlog exists at `review/devlog-2026-05-20.md`
- `production/publishing/writing-lessons.md` exists
- User selects "All three" for communication type

**Expected behavior**:
1. Loads writing-lessons rules
2. Reads activity, concept, and latest devlog
3. Identifies progress moment, design insight, and player hook
4. Asks what to communicate — user selects "All three"
5. Asks "May I write the social post batch to `review/social-posts-[YYYY-MM-DD].md`?"
6. Writes file with three Twitter drafts, one Reddit post, one TikTok caption
7. Auto-applies `/refine-copy`
8. Reports COMPLETE with post count, platform count, and visual flag count

**Assertions**:
- [ ] File exists at `review/social-posts-[YYYY-MM-DD].md`
- [ ] Three Twitter/X posts present (each max 280 chars)
- [ ] One Reddit section present (150–300 words)
- [ ] One TikTok/Instagram caption with exactly five hashtags
- [ ] At least one `[NEEDS]` visual flag present
- [ ] Verdict is `COMPLETE`

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Active State and Concept
**Fixture**:
- `production/session-state/active.md` does not exist
- `design/gdd/game-concept.md` does not exist
- No devlog exists

**Expected behavior**:
1. Reads context files — all absent
2. Skill cannot identify shareable angles from empty context
3. Still presents the `AskUserQuestion` for communication type
4. Proceeds to write what it can, likely with heavy placeholder use
5. Approval gate still fires
6. File written and COMPLETE reported (no hard stop defined for these missing files)

**Assertions**:
- [ ] Skill does not crash on all-missing context
- [ ] Approval gate still fires before write
- [ ] Output file is created after approval

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Progress Update Only
**Fixture**:
- `production/session-state/active.md` exists with concrete build note
- `design/gdd/game-concept.md` exists
- User selects "Progress update (built something)"

**Expected behavior**:
1. Focuses posts on progress moment angle
2. Still writes all three platforms but content emphasizes what was built
3. Reddit post centers on the concrete progress, not design philosophy
4. Player hook Twitter post may still be generated (format includes all three Twitter slots)

**Assertions**:
- [ ] Reddit post gives value-first content about what was built
- [ ] No promises about unbuilt or unscoped features in posts
- [ ] Hashtags are specific to game/genre, not generic (#gaming, #indiedev avoided)

**Case Verdict**: PASS

---

### Case 4: Edge Case — devlog File in wrong directory
**Fixture**:
- `production/publishing/devlog-3-2026-05-25.md` exists (production/publishing path)
- `review/devlog-*.md` does not exist (the path the skill reads is `review/devlog-*.md`)
- Other files exist normally

**Expected behavior**:
1. Skill reads `review/devlog-*.md` — none found at that path
2. Skill continues without devlog context (not a hard-stop condition)
3. Posts are written from remaining context sources

**Assertions**:
- [ ] Skill does not hard-stop when devlog at `review/` path is absent
- [ ] Output file is still generated

**Case Verdict**: PASS

---

### Case 5: Protocol — Write Approval Gate
**Fixture**:
- All context files exist
- User has answered the communication type question
- Skill is at Phase 3 write step

**Expected behavior**:
1. Presents "May I write the social post batch to `review/social-posts-[YYYY-MM-DD].md`?" before writing
2. No file is created if user declines
3. `/refine-copy` runs in-place after write with no second approval

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
- [ ] No auto-write
- [ ] `/refine-copy` runs without additional approval gate

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Character count enforcement for Twitter posts (max 280) is a runtime check — static spec cannot verify generated text length.
- Reddit word count (150–300) is similarly runtime-only.
- Hashtag relevance ("specific and relevant — no #gaming #indiedev spam") is a judgment call testable only at runtime.
- The skill reads `review/devlog-*.md` for devlog context but `/publish-devlog` saves to `production/publishing/devlog-*.md` — this path mismatch in the SKILL.md is a known gap worth flagging during runtime testing.
