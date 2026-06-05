# Skill Spec: /localization-integrate

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/localization-integrate` handles the mid-pipeline exchange with translators. It has three modes: `export` (reads `strings-en.json`, generates a translator brief via `localization-lead`, calls string freeze, and summarizes what to send to translators); `import [locale] [path]` (validates a received translation file for missing keys, placeholder mismatches, and schema errors, then writes it to `assets/data/strings/strings-[locale].json` after approval); and `freeze lift` (records a freeze removal in `production/localization/freeze-status.md` after warning the user of consequences). All three modes write files only after explicit "May I write" approval gates.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `localization-integrate` is a pipeline coordination skill that manages string exchange with external translators. It does not invoke creative-director, technical-director, or producer gate phases. Its freeze mechanism is an internal pipeline control, not a design-phase gate.

---

## Test Cases

### Case 1: Happy Path — Export with Freeze
**Fixture**:
- `assets/data/strings/strings-en.json` exists with 50 strings
- No active freeze (`production/localization/freeze-status.md` absent)
- `design/gdd/game-concept.md` exists with game overview
- Argument: `export`

**Expected behavior**:
1. Reads and validates the source string table
2. Runs quick grep for hardcoded strings — finds none; no warning
3. Confirms freeze is not active
4. Spawns `localization-lead` to generate translator brief
5. Presents the brief; asks "May I write this translator brief to `production/localization/translator-brief-[date].md`?"
6. On approval, writes the brief
7. Asks "Call string freeze now?"
8. On approval, creates `production/localization/freeze-status.md` with status ACTIVE
9. Outputs export summary with paths and next steps

**Assertions**:
- [ ] Translator brief presented before write approval
- [ ] "May I write" prompt for translator brief file
- [ ] "May I write" prompt (or equivalent ask) for freeze-status file
- [ ] Export summary lists string table path, brief path, freeze status
- [ ] Next steps include `/localization-integrate import [locale] [path]` pointer
- [ ] `COMPLETE` or equivalent verdict in summary

**Case Verdict**: PASS

---

### Case 2: Failure — Import with FAIL Validation
**Fixture**:
- `assets/data/strings/strings-en.json` exists with 40 keys
- Received translation file at `tmp/ja-translations.json` is missing 5 keys and has 2 placeholder mismatches
- Argument: `import ja tmp/ja-translations.json`

**Expected behavior**:
1. Reads source table and received translation file
2. Spawns `localization-specialist` to validate
3. Validator returns FAIL with list of blocking issues
4. Skill surfaces all blocking items to user
5. Stops — does not ask to write the locale file
6. Instructs user to return file to translator with the error report

**Assertions**:
- [ ] FAIL verdict surfaced clearly with blocking issue list
- [ ] No write prompt for `strings-ja.json`
- [ ] User directed to return file to translator
- [ ] Skill does not crash or continue past FAIL

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Import PASS WITH WARNINGS (Extra Keys)
**Fixture**:
- `assets/data/strings/strings-en.json` has 30 keys
- Received `fr-translations.json` has 30 matching keys plus 2 extra orphaned keys
- Argument: `import fr tmp/fr-translations.json`

**Expected behavior**:
1. Validation returns PASS WITH WARNINGS — 2 extra/orphaned keys listed
2. Skill presents preview: "I will write `strings-fr.json`. [N] strings imported. [N] warnings."
3. Asks: "May I write `assets/data/strings/strings-fr.json`?"
4. On approval, writes file with orphaned keys stripped

**Assertions**:
- [ ] PASS WITH WARNINGS verdict shown with orphaned key list
- [ ] Preview shows N strings and N warnings before approval prompt
- [ ] "May I write" fires before writing locale file
- [ ] Orphaned keys removed from written file

**Case Verdict**: PASS

---

### Case 4: Edge Case — Freeze Lift with Post-Freeze Violations
**Fixture**:
- `production/localization/freeze-status.md` shows `**Status**: ACTIVE` with 3 post-freeze changes listed
- Argument: `freeze lift`

**Expected behavior**:
1. Reads freeze-status.md; detects ACTIVE freeze with post-freeze changes
2. Displays full freeze record (called date, total at freeze, post-freeze changes)
3. Shows warning about consequences of lifting
4. Asks: "Why are you lifting the freeze?"
5. Asks: "May I update `production/localization/freeze-status.md` to record the lift?"
6. On approval, updates status to LIFTED, appends reason and date
7. Outputs summary with next steps

**Assertions**:
- [ ] Freeze record and consequences displayed before any action
- [ ] Reason prompt fires before file write
- [ ] "May I update" approval gate fires before writing
- [ ] Status field changed to LIFTED in output
- [ ] Next steps include `/localization-integrate export` to re-freeze

**Case Verdict**: PASS

---

### Case 5: Protocol — Export String Freeze Write Approval
**Fixture**:
- `strings-en.json` exists
- Argument: `export`
- Translator brief generated and approved for write
- User asked about string freeze — approves

**Expected behavior**:
1. Translator brief write prompt fires and is approved
2. Freeze-status write prompt fires separately
3. Both files written only after their respective approvals
4. No file is auto-created

**Assertions**:
- [ ] Uses "May I write" before translator brief file write
- [ ] Uses "May I write" (or equivalent) before freeze-status file write
- [ ] Presents translator brief content before approval
- [ ] No auto-write of either file

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The export mode's hardcoded-string warning is advisory (continues regardless) — the spec doesn't test what happens if the user disputes the warning. That decision is left to user judgment at runtime.
- The freeze lift "why" prompt answer is stored in the freeze-status.md; verifying the content was correctly recorded requires reading the file after the run — a runtime-only check.
- Whether the `localization-lead` subagent correctly extracts character glossary and placeholder references from narrative docs is a runtime-only quality check.
