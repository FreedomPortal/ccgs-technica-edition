# Skill Spec: /refine-copy

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/refine-copy` removes AI writing patterns from text across 8 editing passes: structural tells, significance inflation, AI vocabulary, grammar-level tics, sentence rhythm, hedging/filler, connective tissue, and human texture. Operates in two modes: `rewrite` (applies all passes, returns revised text + changes table) and `review-only` (flags AI patterns with alternatives). Accepts a file path or pasted text. Called automatically by all export skills without an approval gate; when called directly by the user, approval is required before writing. Verdict: COMPLETE.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (Phase 0 + 8 editing passes + output section)
- [ ] At least one verdict keyword present (`COMPLETE`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present (Collaborative Protocol section covers this)
- [ ] Next-step handoff section present at end (Collaborative Protocol notes export-skill integration)

---

## Director Gate Checks

- **N/A**: `/refine-copy` is a copy-editing utility. No director phase gates — it is called by export skills or used standalone without pipeline gate implications.

---

## Test Cases

### Case 1: Happy Path — Rewrite mode on a file

**Fixture**:
- User invokes `/refine-copy path/to/store-description.md`
- File contains classic AI patterns: "pivotal moment," "delve," "Moreover," metronomic sentence length, significance inflation

**Expected behavior**:
1. Phase 0 skipped (file path provided directly)
2. Skill reads the file
3. Applies all 8 passes in sequence
4. Outputs rewritten content followed by a Changes table showing which passes made edits
5. Asks: "May I write the rewritten version back to [path]?"
6. On approval, writes file in-place
7. Verdict: COMPLETE

**Assertions**:
- [ ] All 8 passes applied (not just vocabulary)
- [ ] Changes table included with pass / what changed / examples columns
- [ ] Approval asked before writing in direct-invocation mode
- [ ] No AI patterns introduced by the refinement itself
- [ ] Verdict: COMPLETE at end

**Case Verdict**: PASS

---

### Case 2: Failure — File path not found

**Fixture**:
- User passes `path/to/missing.md` that does not exist

**Expected behavior**:
1. Skill attempts to read the file
2. File not found
3. Reports the error and suggests checking the path
4. Does not proceed with editing

**Assertions**:
- [ ] Explicit error when file is not found
- [ ] No empty output or silent failure
- [ ] No file writes attempted

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Review-only mode (no rewrite)

**Fixture**:
- User invokes with `--review-only` flag OR selects "Review only" in Phase 0
- File contains several flagged patterns

**Expected behavior**:
1. Applies all detection passes
2. Outputs flags per passage with pattern name and suggested alternative
3. Consolidates overlapping patterns (pattern stacking) into single findings
4. Does NOT rewrite the file
5. Does NOT ask to write — review-only mode is read-only

**Assertions**:
- [ ] No file write attempted in review-only mode
- [ ] Overlapping patterns consolidated into single entry (not inflated count)
- [ ] Each flag names the specific pass and pattern triggered
- [ ] Verdict: COMPLETE at end

**Case Verdict**: PASS

---

### Case 4: Edge Case — Called by export skill (auto mode)

**Fixture**:
- `/publish-steam-page` calls `/refine-copy` automatically on the generated copy
- File path is pre-set by the calling skill

**Expected behavior**:
1. Phase 0 skipped (file already set by caller)
2. All 8 passes applied
3. File edited in-place
4. No approval gate — export skill's own gate already covered this
5. Changes table NOT added to the saved file (only shown in conversation)
6. Returns to calling skill with COMPLETE

**Assertions**:
- [ ] No `AskUserQuestion` approval gate in auto-call mode
- [ ] Changes table excluded from saved file content
- [ ] File edited in-place silently
- [ ] Pass 8 (Soul/voice) not applied if content is formal documentation — only for marketing/editorial text

**Case Verdict**: PASS

---

### Case 5: Protocol — Direct user invocation requires approval before write

**Fixture**:
- User invokes directly: `/refine-copy design/narrative/intro-text.md`
- Rewrite mode selected

**Expected behavior**:
1. Skill reads and rewrites
2. Shows rewritten content + changes table in conversation
3. Asks: "May I write the rewritten version back to `design/narrative/intro-text.md`?"
4. User can decline — original file unchanged
5. If approved, writes in-place

**Assertions**:
- [ ] "May I write" approval gate present for direct user invocation
- [ ] Original file not overwritten before approval
- [ ] If user declines, no write occurs
- [ ] Rewritten content already shown before approval gate (user can copy manually if they decline)

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before overwriting files in direct-user-invocation mode
- [ ] Presents rewritten content before write approval
- [ ] No approval gate when called by export skills (documented in Collaborative Protocol)
- [ ] Changes table shown in conversation but NOT written to saved files

---

## Coverage Notes

- Pass 8 (Soul/voice) suppression for formal docs (patch notes, legal text) is behavioral — verified only at runtime
- Pattern stacking consolidation logic cannot be unit-tested; requires sample text evaluation
- Auto-call behavior from export skills is an integration concern; tested here only for expected protocol (no gate)
- "Read it out loud" test is a human judgment check, not machine-verifiable
