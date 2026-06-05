# Skill Spec: /publish-check

> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-05-26

## Skill Summary

`/publish-check` audits the publishing pipeline against the current development stage. It reads the publishing roadmap, milestone files, session state, and community status; cross-references the `production/publishing/` folder against roadmap task status; then flags items as Overdue (🔴), Unlocked Now (🟡), or Upcoming (🟢). Output is a structured audit report with a single most-urgent action. The skill also runs automatically at session start via `session-start.sh`. Verdict is COMPLIANT, CONCERNS, or OVERDUE.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (phases 1, 1b, 2, 3, 4, 5, 6)
- [x] At least one verdict keyword present (COMPLIANT, CONCERNS, OVERDUE)
- [x] `allowed-tools` includes Write/Edit: `"May I write"` language present (Phase 5: "May I write these audit results to `production/publishing/publishing-roadmap.md`?")
- [x] Next-step handoff present (Phase 6 offers: most urgent task, /marketing-plan, /community-plan)

---

## Director Gate Checks

- **N/A**: `/publish-check` is a status/audit skill with no director gate triggers. It surfaces actions but does not gate phase transitions.

---

## Test Cases

### Case 1: Happy Path — COMPLIANT result

**Fixture**:
- `production/publishing/publishing-roadmap.md` exists, no overdue tasks
- All completed tasks marked ✅
- Dev stage matches roadmap "Current dev stage" field
- `production/publishing/itch-page.md` exists and roadmap marks it ✅

**Expected behavior**:
1. Phase 1 reads roadmap, milestones, active.md, community-status.md
2. Phase 1b globs `production/publishing/` — finds itch-page.md, confirms roadmap is marked ✅
3. Phase 2 confirms dev stage matches roadmap
4. Phase 3 finds no overdue, some upcoming items
5. Phase 4 outputs COMPLIANT audit report with 0 🔴 items
6. Phase 5 asks "May I write these audit results to publishing-roadmap.md?" (user may decline)
7. Phase 6 offers next action via AskUserQuestion

**Assertions**:
- [ ] Audit report includes all four emoji sections (🔴, 🟡, 🟢, ✅)
- [ ] Verdict is COMPLIANT when no overdue items and no folder mismatches
- [ ] Single most-urgent action identified in `=== MOST URGENT ACTION ===` section
- [ ] Folder check passes with "all artifacts match roadmap."
- [ ] Roadmap not written without user approval

**Case Verdict**: PASS

---

### Case 2: Failure — No roadmap found

**Fixture**:
- `production/publishing/publishing-roadmap.md` does not exist

**Expected behavior**:
1. Phase 1 attempts to read roadmap
2. Fails with: "No publishing roadmap found. Run `/marketing-plan` first to create one."
3. Skill stops — does not proceed to audit

**Assertions**:
- [ ] Skill stops at Phase 1 if roadmap is missing
- [ ] Error message directs to `/marketing-plan`
- [ ] No files written
- [ ] No partial audit output displayed

**Case Verdict**: PASS

---

### Case 3: Overdue items — OVERDUE verdict

**Fixture**:
- Roadmap exists; current dev stage is Alpha
- Two tasks from Pre-Production phase still marked `not started`
- One task marked ✅ in roadmap but no corresponding file in `production/publishing/`

**Expected behavior**:
1. Phase 3 identifies two tasks as 🔴 Overdue (belonged to earlier phase)
2. One missing artifact flagged as ⚠️ Missing artifact in Phase 1b folder check
3. Phase 4 outputs OVERDUE verdict with 🔴 section listing both tasks
4. FOLDER CHECK section shows the missing artifact discrepancy

**Assertions**:
- [ ] 🔴 items listed with phase they belong to and suggested action
- [ ] ⚠️ missing artifact flagged when roadmap ✅ but no file on disk
- [ ] Verdict is OVERDUE (not CONCERNS) when 🔴 items exist
- [ ] Most urgent action points to highest-priority 🔴 item

**Case Verdict**: PASS

---

### Case 4: Edge Case — Untracked artifact on disk

**Fixture**:
- `production/publishing/devlog-4-2026-05-22.md` exists on disk
- Corresponding "Devlog #4 published" task in roadmap is NOT marked ✅

**Expected behavior**:
1. Phase 1b detects devlog file but roadmap task not marked complete
2. Flags as 📁 Untracked in FOLDER CHECK section
3. Audit report suggests updating roadmap to reflect actual state

**Assertions**:
- [ ] Untracked artifact identified with "📁 Untracked" flag
- [ ] Does NOT automatically mark roadmap ✅ without user approval
- [ ] Phase 5 offers to update roadmap including this discrepancy

**Case Verdict**: PASS

---

### Case 5: Edge Case — Dev stage mismatch

**Fixture**:
- `production/stage.txt` says "Production"
- Roadmap "Current dev stage" field says "Pre-Production"

**Expected behavior**:
1. Phase 2 detects discrepancy between milestone file and roadmap field
2. Notes the discrepancy in output
3. Uses milestone file (stage.txt) as source of truth for the audit

**Assertions**:
- [ ] Discrepancy noted explicitly in audit output
- [ ] Milestone file treated as source of truth, not roadmap field
- [ ] Audit proceeds using the milestone-derived stage

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Uses `"May I write"` before updating publishing-roadmap.md (Phase 5 — AskUserQuestion)
- [x] Presents full audit report before asking to update roadmap
- [x] Ends with AskUserQuestion offering next action (Phase 6)
- [x] Does not auto-write roadmap without user approval

---

## Coverage Notes

- Automatic session-start invocation (via hook) is a runtime behavior not testable via static spec
- Community platform status read from `community-status.md` is referenced but audit logic for it is not fully specified in the skill body
- File pattern → roadmap task mapping table covers only 4 patterns; files with no mapping are informational only
