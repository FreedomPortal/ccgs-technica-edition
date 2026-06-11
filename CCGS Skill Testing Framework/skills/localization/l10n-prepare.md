# Skill Spec: /l10n-prepare

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/l10n-prepare` is the first stage of the localization pipeline. It accepts an optional mode argument (`scan`, `wrap`, or `scaffold`) and an optional `--review` flag. In `scan` mode it reads source code under `src/` and reports hardcoded user-facing strings that are not yet wrapped in the engine's localization function (`tr()`, `LOCTEXT()`, etc.). In `scaffold` mode it creates the initial `assets/data/strings/strings-en.json` string table structure if none exists. In `wrap` mode it combines the scan with proposed edits — showing per-file diffs and asking approval before writing — then adds new entries to the source string table. Output is a summary report with counts and next-step pointers.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: Localization-prepare is a pipeline preparation skill, not a design or architecture gate. It does not trigger creative-director, technical-director, or producer gate phases. Its output (a populated string table) feeds downstream localization skills rather than a phase-gate verdict.

---

## Test Cases

### Case 1: Happy Path — Scan Finds Hardcoded Strings
**Fixture**:
- `assets/data/strings/strings-en.json` exists with some entries
- `src/` contains GDScript files with `.text = "Start Game"` and similar hardcoded UI strings
- No `--review` arg; `production/review-mode.txt` does not exist (defaults to `lean`)

**Expected behavior**:
1. Resolves review mode to `lean`
2. Parses argument — defaults to `scan`
3. Reads `technical-preferences.md` and detects Godot; sets `[LOC_FUNC]` = `tr()`
4. Spawns `localization-specialist` to scan `src/` for hardcoded strings
5. Presents grouped scan report (UI code / Dialogue / System messages / Other)
6. Stops — does not modify any files (scan mode is read-only)
7. Phase 5 summary shows remaining hardcoded strings count and next-step pointer

**Assertions**:
- [ ] Review mode resolved without prompting user
- [ ] Correct localization function (`tr()`) identified for Godot
- [ ] Scan report groups findings by category
- [ ] No files modified (confirmed by no Write/Edit calls)
- [ ] Summary includes `Next steps: /l10n-integrate export` pointer
- [ ] Verdict keyword `COMPLETE` present in summary

**Case Verdict**: PASS

---

### Case 2: Failure — No Source Code Present
**Fixture**:
- `assets/data/strings/` does not exist
- `src/` directory is empty or absent
- Argument: `scan`

**Expected behavior**:
1. Spawns `localization-specialist` to scan `src/`
2. No hardcoded strings found (empty source)
3. Outputs: "Scan complete — no hardcoded strings found. Either the project is already localized or source code has not been written yet."
4. Stops without error

**Assertions**:
- [ ] No crash or unhandled error
- [ ] Correct "no hardcoded strings" message displayed verbatim (or equivalent)
- [ ] No files created or modified
- [ ] Skill terminates gracefully

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Scaffold Mode on Empty Project
**Fixture**:
- `assets/data/strings/` does not exist
- Argument: `scaffold`

**Expected behavior**:
1. Checks that `assets/data/strings/` is absent
2. Presents proposed directory structure and JSON schema to user
3. Asks: "May I create `assets/data/strings/strings-en.json` with this structure?"
4. On approval, creates the file with a header comment entry only
5. Outputs verdict: `COMPLETE — string table scaffolded`

**Assertions**:
- [ ] "May I create" approval gate fires before any file write
- [ ] Proposed JSON schema shown to user before approval
- [ ] File created only after approval
- [ ] `COMPLETE` verdict keyword in output

**Case Verdict**: PASS

---

### Case 4: Edge Case — Scaffold Called When Table Already Exists
**Fixture**:
- `assets/data/strings/strings-en.json` already exists with content
- Argument: `scaffold`

**Expected behavior**:
1. Detects existing string table
2. Outputs: "`assets/data/strings/` already exists. Use `/l10n-prepare wrap` to add new strings..."
3. Stops — does not overwrite or re-scaffold

**Assertions**:
- [ ] Existing file is not overwritten
- [ ] Correct advisory message pointing to `wrap` and `/l10n-sync`
- [ ] Skill stops cleanly without further prompts

**Case Verdict**: PASS

---

### Case 5: Protocol — Wrap Mode Approval Gates
**Fixture**:
- `assets/data/strings/strings-en.json` exists
- `src/` contains 3 files with hardcoded strings (2 strings each)
- Argument: `wrap`

**Expected behavior**:
1. Runs scan to gather findings
2. Presents proposed changes summary (N strings across M files)
3. Asks: "May I proceed with wrapping these strings?"
4. For each source file: spawns specialist to produce diff, presents diff, asks "May I write this change to [filepath]?"
5. After source file approvals: presents new string table entries, asks "May I add these [N] entries to `assets/data/strings/strings-en.json`?"
6. Never writes any file without an explicit per-file approval

**Assertions**:
- [ ] Uses "May I write" before any file modification
- [ ] Presents content (diff or entry list) before each approval gate
- [ ] No auto-write — every file has a separate prompt
- [ ] String table entries appended (not overwritten)

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Engine detection relies on `technical-preferences.md` being configured. If the engine field is still `[TO BE CONFIGURED]`, the localization function mapping cannot be determined — this path is not explicitly handled in the SKILL.md and would be a runtime gap.
- Whether the `localization-specialist` subagent correctly excludes debug prints, file paths, and enum names from scan results is a runtime-only behavior — cannot be verified statically.
- The `--review full` path would trigger additional review gates downstream in `/l10n-qa` but has no visible effect within `l10n-prepare` itself.
