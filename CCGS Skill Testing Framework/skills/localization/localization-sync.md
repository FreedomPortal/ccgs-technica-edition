# Skill Spec: /localization-sync

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/localization-sync` detects translation drift after English source strings change post-freeze. It has three entry points: a `status` argument (read-only coverage matrix showing translated/stale/missing/orphaned counts per locale); a `--locale [code]` flag to limit sync to a single locale; and no argument (sync all locales). In full sync mode it spawns a `localization-specialist` to compare source `"source"` fields against those stored in locale files, then surfaces STALE, MISSING, and ORPHANED keys. It asks approval before marking stale keys in locale files, optionally generates a re-translation request document, and appends a sync record to the freeze-status file if a freeze is active. All file writes require explicit per-file approval.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `localization-sync` is a pipeline maintenance skill that keeps translation files aligned with source text changes. It does not invoke creative-director, technical-director, or producer gate phases. Freeze violation warnings are surfaced to the user for manual resolution rather than routed to a gate agent.

---

## Test Cases

### Case 1: Happy Path — Stale Keys Detected and Marked
**Fixture**:
- `assets/data/strings/strings-en.json` has 20 keys; 2 source texts changed since last translation
- `assets/data/strings/strings-ja.json` exists; those 2 keys have old source text in `"source"` field
- No freeze active (`freeze-status.md` absent)
- No argument (sync all)

**Expected behavior**:
1. Reads source and all locale files
2. Spawns `localization-specialist` — finds 2 STALE keys in `strings-ja.json`, 0 MISSING, 0 ORPHANED
3. Presents sync report table
4. No freeze active — no freeze violation section
5. Asks: "May I mark stale and missing keys in the locale translation files?"
6. On approval, spawns specialist to mark stale keys; presents diff of `strings-ja.json`
7. Asks: "May I write these changes to `assets/data/strings/strings-ja.json`?"
8. On approval writes the file
9. Asks whether to generate re-translation request; if yes, generates and asks write approval
10. Phase 8 summary lists locales checked, stale/missing/orphaned counts, next steps

**Assertions**:
- [ ] Sync report presented before any write
- [ ] Freeze violation section absent (no active freeze)
- [ ] "May I mark stale" prompt fires before writes
- [ ] Per-file diff presented before per-file write approval
- [ ] "May I write" fires for locale file
- [ ] Summary includes `/localization-integrate import [locale] [path]` pointer

**Case Verdict**: PASS

---

### Case 2: Failure — No Locale Files Found
**Fixture**:
- `assets/data/strings/strings-en.json` exists
- No `strings-[locale].json` files present
- No argument (sync all)

**Expected behavior**:
1. Reads source table
2. Globs locale files — none found
3. Outputs: "No translation files found. Run `/localization-integrate import [locale] [path]` after receiving translations."
4. Stops cleanly

**Assertions**:
- [ ] Correct error message with next-step command
- [ ] No subagents spawned
- [ ] Skill terminates without error

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Status Mode (Read-Only Coverage Matrix)
**Fixture**:
- `assets/data/strings/strings-en.json` has 25 keys
- `strings-ja.json` has 25 keys (20 translated, 3 stale, 2 needs_translation)
- `strings-fr.json` has 23 keys (23 translated, 0 stale, 0 needs_translation; 2 missing from source)
- `production/localization/freeze-status.md` shows `**Status**: ACTIVE`
- Argument: `status`

**Expected behavior**:
1. Reads source and all locale files
2. Reads freeze-status.md — reports ACTIVE freeze
3. Outputs coverage matrix table with per-locale counts
4. Shows freeze status header
5. Stops — does NOT run stale detection, does NOT modify any files

**Assertions**:
- [ ] Coverage matrix displayed with correct columns (Locale, Total, Translated, Stale, Needs Translation, Missing, Coverage %)
- [ ] Freeze status shown at top of output
- [ ] No files written or modified
- [ ] Skill stops after coverage matrix — no Phase 3+ execution

**Case Verdict**: PASS

---

### Case 4: Edge Case — Freeze Active with Stale Keys (Freeze Violation)
**Fixture**:
- `production/localization/freeze-status.md` is ACTIVE (called 2 weeks ago)
- `assets/data/strings/strings-en.json` has 2 keys with source text changed since freeze
- `assets/data/strings/strings-de.json` exists
- No argument

**Expected behavior**:
1. Stale detection finds 2 STALE keys in `strings-de.json`
2. Reads freeze-status.md — freeze is ACTIVE
3. Surfaces freeze violation warning prominently: "[N] keys have changed or were added after freeze"
4. Presents options A (revert English) and B (lift freeze)
5. Continues to mark stale keys regardless (correct behavior per spec)
6. Stale marking approval gate still fires

**Assertions**:
- [ ] Freeze violation warning displayed before stale-marking prompt
- [ ] Options A and B presented
- [ ] Stale-marking still proceeds (not blocked by freeze warning)
- [ ] "May I mark stale" prompt still fires
- [ ] "previous_translation" field preserved in stale entries

**Case Verdict**: PASS

---

### Case 5: Protocol — Per-File Write Approval for Stale Marking
**Fixture**:
- Two locale files: `strings-ja.json` and `strings-fr.json`, both with stale keys
- No argument (sync all)

**Expected behavior**:
1. Stale detection finds stale keys in both locale files
2. Stale-marking approval prompt asks for permission to mark both
3. Specialist shows diffs for both files
4. Each file gets its own "May I write these changes to `strings-[locale].json`?" prompt
5. Neither file written without individual approval

**Assertions**:
- [ ] Uses "May I write" before each locale file write
- [ ] Diff presented per file before per-file approval
- [ ] No auto-write — each file requires separate approval

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- ORPHANED keys are flagged with `"status": "orphaned"` but never auto-removed — the spec says the user decides. Verifying the user sees and acts on orphaned flags is a runtime behavior.
- The `"previous_translation"` field preservation for stale entries is critical for translator reference but can only be verified by reading the written locale file content — a runtime check.
- The re-translation request generation step (Phase 6) is conditional on user answering "yes" — the case that the user declines is not explicitly specced but should result in graceful skip and still produce the Phase 8 summary.
- Single-locale mode (`--locale ja`) exercises the same phases as full sync but filtered — not separately cased here since the logic is identical except for the glob filter.
