# Skill Spec: /localization-cultural-review

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/localization-cultural-review` audits English SOURCE content for cultural landmines before translation begins. It is distinct from `/localization-qa` Phase 4, which checks translation quality — this skill checks whether source strings, UI descriptions, asset names, and GDD content contain symbols, numbers, humor, names, violence references, or text-in-images that will cause issues in specific target locales. It asks the user for target locales and scan scope (Full or Scoped), spawns a `localization-lead` subagent to run six cultural check categories, presents findings grouped by severity (HIGH / MEDIUM / LOW), prompts per-finding action decisions, then asks approval to write a report to `production/localization/cultural-review-[date].md`. Output feeds into the `/localization-integrate export` brief.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `localization-cultural-review` is a source-audit skill that runs before translation export. It does not trigger creative-director, technical-director, or producer gate phases. HIGH severity findings may require source text changes, but those changes go through the normal Write/Edit approval protocol within this skill rather than a separate gate agent.

---

## Test Cases

### Case 1: Happy Path — Findings Across Multiple Severities
**Fixture**:
- `assets/data/strings/strings-en.json` has 40 keys including some with number "4" in values, an English idiom, and a thumbs-up emoji reference
- `design/gdd/game-concept.md` and `design/narrative/` exist
- Target locales: `ja`, `ko`
- Scope: Full

**Expected behavior**:
1. Phase 1: Asks for target locales (presented as checklist from `assets/data/strings/`), asks Full vs Scoped
2. Phase 2: Spawns `localization-lead` with full scan prompt covering all 6 check categories
3. Phase 3: Presents findings grouped by severity — HIGH (thumbs-up, ja/ko), MEDIUM (English idiom), LOW (number 4 usage)
4. Phase 4: For each HIGH and MEDIUM finding, presents action options (A/B/C/D); asks if user accepts all LOW findings
5. Phase 5: Asks "May I write the cultural review report to `production/localization/cultural-review-[date].md`?"
6. On approval, writes report with decisions recorded
7. Phase 6: Outputs integration handoff noting keys with translator instructions

**Assertions**:
- [ ] Findings grouped by HIGH / MEDIUM / LOW severity
- [ ] Per-finding action prompt fires for each HIGH and MEDIUM item
- [ ] Bulk acceptance prompt fires for LOW findings
- [ ] "May I write" fires before report is written
- [ ] Report includes decisions recorded per finding
- [ ] Handoff output counts translator-instruction keys and locale-excluded keys
- [ ] Next step points to `/localization-integrate export`

**Case Verdict**: PASS

---

### Case 2: Failure — No String Table Configured Yet
**Fixture**:
- `assets/data/strings/strings-en.json` does not exist
- `assets/data/strings/` directory is absent
- Target locales: to be specified by user

**Expected behavior**:
1. Phase 1: Checklist of locales cannot be derived from `assets/data/strings/` (empty/missing)
2. Skill asks user to specify intended target markets
3. Spawns `localization-lead` with empty/minimal string table input
4. Subagent scans GDDs and src/ but finds minimal strings to review
5. Findings may be "No cultural issues found" or minimal
6. Skill completes gracefully with whatever was found

**Assertions**:
- [ ] Skill does not crash when string table is absent
- [ ] User prompted to specify locales manually
- [ ] Output is graceful (no unhandled error)

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Scoped Review (Single System)
**Fixture**:
- `assets/data/strings/strings-en.json` exists with 60 keys
- User selects Scope B (Scoped) and specifies "combat system" strings only
- Target locales: `ar`, `de`

**Expected behavior**:
1. Phase 1: Scope recorded as "combat system"
2. Phase 2: Spawn prompt includes scoped description; subagent focuses on combat-related keys and GDD
3. Findings reflect only the scoped content
4. Report header shows "Scope: Scoped — combat system"

**Assertions**:
- [ ] Scope passed to subagent prompt correctly
- [ ] Report header reflects scoped scope description
- [ ] Findings do not include non-combat keys (runtime quality check)

**Case Verdict**: PASS

---

### Case 4: Edge Case — Zero Findings (All Clean)
**Fixture**:
- String table has 20 keys with no cultural landmines for target locales `fr`, `de`
- No problematic symbols, numbers, idioms, or text-in-images
- Target locales: `fr`, `de`

**Expected behavior**:
1. Phase 2: Subagent scans all 6 categories — no findings
2. Phase 3: Outputs "No cultural issues found for target locales. Ready to proceed to /localization-integrate export."
3. Phase 4: No per-finding action prompts (nothing to decide)
4. Phase 5: May still ask to write a report (recording a clean audit); or skip if nothing to write
5. Phase 6: Handoff notes 0 translator-instruction keys, 0 locale exclusions

**Assertions**:
- [ ] Clean audit message displayed verbatim (or equivalent)
- [ ] No action decision prompts fire when findings list is empty
- [ ] Next step points to `/localization-integrate export`

**Case Verdict**: PASS

---

### Case 5: Protocol — Report Write Approval with Source Change Proposed
**Fixture**:
- HIGH finding identified: a thumbs-up emoji reference for `ar` locale
- User selects Option A (fix source text now)

**Expected behavior**:
1. Action A selected: skill must show exact proposed source text diff before making any edit
2. Approval received for source text change
3. Edit made to source string table
4. Report write approval fires: "May I write the cultural review report to `production/localization/cultural-review-[date].md`?"
5. No auto-write of either source file or report file

**Assertions**:
- [ ] Source text diff shown before approval for Option A fix
- [ ] "May I write" fires for source file change (per collaborative protocol)
- [ ] "May I write" fires for report file
- [ ] Both files require separate approvals

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The six cultural check categories (Symbols, Numbers, Humour, Violence, Names, Text-in-Images) are assessed by the `localization-lead` subagent — whether the subagent correctly identifies all landmines for all target locales is a runtime quality check beyond static spec verification.
- Locale exclusion decisions (Option C) generate metadata for the export brief; verifying this metadata is correctly passed to `/localization-integrate export` requires an end-to-end pipeline test.
- The SKILL.md does not specify what happens if the user selects conflicting actions for the same key across two target locales (e.g., Option A for `ja` but Option B for `ar`). This is a runtime ambiguity gap.
