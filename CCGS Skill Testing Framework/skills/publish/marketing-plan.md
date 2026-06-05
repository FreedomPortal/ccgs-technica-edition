# Skill Spec: /marketing-plan

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/marketing-plan` creates or updates the publishing roadmap for the game project. It reads the game concept, current milestones, and any existing roadmap, then maps development phases (Pre-Production through Launch) to publishing tasks with status tracking. On first run it gathers dev stage, target launch window, and community platform choices, then writes `production/publishing/publishing-roadmap.md` and (if absent) `production/publishing/community-status.md`. On subsequent runs it offers a review-and-update vs. start-fresh choice. The skill ends with a COMPLETE verdict and pointers to `/publish-check` and `/community-plan`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/marketing-plan` is a publishing utility skill. It does not invoke a director-tier gate check. The skill itself is a prerequisite for other publishing skills rather than a recipient of gate approval.

---

## Test Cases

### Case 1: Happy Path — First-Run Roadmap Creation
**Fixture**:
- `design/gdd/game-concept.md` exists with title, genre, platforms
- No `production/publishing/publishing-roadmap.md` exists
- No `production/publishing/community-status.md` exists

**Expected behavior**:
1. Reads `game-concept.md` and any milestone files without error
2. Skips the "update or start fresh" question (no existing roadmap)
3. Asks three batched questions: dev stage, launch window, community platforms
4. Presents roadmap content for review
5. Asks `"May I write the publishing roadmap to production/publishing/publishing-roadmap.md?"`
6. Writes `publishing-roadmap.md` with all six phases populated
7. Writes `community-status.md` because it does not exist
8. Runs humanize pass on saved files
9. Outputs summary with COMPLETE verdict and next-step pointers

**Assertions**:
- [ ] No "update or start fresh" question fired
- [ ] Three AskUserQuestion calls for baseline (stage, window, platforms)
- [ ] `"May I write"` approval gate present before file writes
- [ ] Output file contains Phase 1 through Phase 6 table headings
- [ ] `community-status.md` created alongside roadmap
- [ ] Verdict keyword `COMPLETE` present in output
- [ ] Handoff mentions `/publish-check` and `/community-plan`

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Game Concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- No other publishing files present

**Expected behavior**:
1. Skill reads for `game-concept.md` and finds nothing
2. Emits failure message: `"No game concept found. Run /brainstorm first."`
3. Does not proceed to ask any questions or write any files

**Assertions**:
- [ ] Failure message references `/brainstorm`
- [ ] No AskUserQuestion calls issued
- [ ] No files written
- [ ] Skill halts before Phase 3

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Update Existing Roadmap
**Fixture**:
- `design/gdd/game-concept.md` exists
- `production/publishing/publishing-roadmap.md` already exists with Phase 1–3 populated
- `production/publishing/community-status.md` already exists

**Expected behavior**:
1. Detects existing roadmap and presents the update-vs-start-fresh question
2. User selects "Review and update existing"
3. Loads existing roadmap content
4. Presents delta or review summary to user
5. Asks approval before overwriting the roadmap file
6. Does NOT recreate `community-status.md` (already exists)
7. Outputs COMPLETE verdict

**Assertions**:
- [ ] "Review and update existing" / "Start fresh" question fired
- [ ] Existing content loaded and incorporated (not discarded)
- [ ] Approval gate fires before any write
- [ ] `community-status.md` not overwritten when already present
- [ ] COMPLETE verdict in output

**Case Verdict**: PASS

---

### Case 4: Edge Case — Start Fresh Archival
**Fixture**:
- `design/gdd/game-concept.md` exists
- `production/publishing/publishing-roadmap.md` exists (old content)
- User selects "Start fresh (archive the old one)"

**Expected behavior**:
1. Detects existing roadmap; user selects start fresh
2. Old roadmap is archived (renamed or moved, not silently deleted)
3. Proceeds through Phase 3 questions as if first run
4. Writes new roadmap from scratch
5. Outputs COMPLETE verdict

**Assertions**:
- [ ] Old file is archived before new content is written
- [ ] Phase 3 baseline questions re-asked (stage, window, platforms)
- [ ] New roadmap written with fresh phase tables
- [ ] COMPLETE verdict present

**Case Verdict**: PASS

---

### Case 5: Protocol — Approval Gate Before File Writes
**Fixture**:
- `design/gdd/game-concept.md` exists, no roadmap exists
- Skill has completed Phase 3 and drafted roadmap content

**Expected behavior**:
1. Skill presents roadmap structure/summary to user
2. Asks `"May I write the publishing roadmap to production/publishing/publishing-roadmap.md?"` before any Write call
3. Only writes after explicit user confirmation
4. Does not auto-write either the roadmap or `community-status.md`

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

- The humanize writing pass (Phase 6, calls `/refine-copy` in-place) runs automatically per the SKILL.md and cannot be verified statically — it is a runtime-only behavior.
- The `community-status.md` creation gate ("if it doesn't exist") requires runtime state detection; static analysis can only confirm the conditional logic is described.
- Status emoji color-coding (🔴 🟡 🟢 ✅) in the roadmap template is a formatting detail verifiable only by inspecting actual file output.
- The "Overdue Items" and "Unlocked Now" sections are described as auto-populated by `/publish-check` — the skill itself leaves them as placeholder text; the populated state is a cross-skill behavior not testable within this skill alone.
