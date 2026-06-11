# Skill Spec: /l10n-qa

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/l10n-qa` runs a dedicated Language Quality Assurance (LQA) pass for a specified locale after translations have been integrated. It takes an optional locale argument (defaults to prompting the user), reads the source and translated string tables, then executes three analysis phases via subagents: (1) automated checks for completeness, placeholder accuracy, character limits, encoding errors, and stale markers; (2) a cultural review in `full` mode only; (3) a UI overflow risk assessment flagging translated strings over 130% of English length. It compiles a PASS / PASS WITH CONDITIONS / FAIL verdict and asks approval to write an LQA report to `production/localization/lqa-[locale]-[date].md`. The report is a required artifact for the Polish → Release gate.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `l10n-qa` produces a per-locale verdict report that feeds into the Polish → Release gate (`/gate-check`), but the skill itself does not invoke director-level gate agents. The gate integration is described in the report template ("This report is required by the Polish → Release gate") rather than implemented as a director phase within this skill.

---

## Test Cases

### Case 1: Happy Path — Clean Translation Passes All Checks
**Fixture**:
- `assets/data/strings/strings-en.json` has 30 keys with context fields (some with char limits)
- `assets/data/strings/strings-de.json` has all 30 keys translated, no missing placeholders, all within char limits, no stale markers
- Review mode: `lean` (cultural review skipped)
- Argument: `de`

**Expected behavior**:
1. Parses locale from argument (`de`)
2. Reads both string tables and any existing cultural review file
3. Spawns `localization-specialist` for automated checks — all pass
4. Cultural review skipped; notes "Cultural review skipped — Lean mode." in report
5. Spawns `localization-specialist` for UI overflow — no violations or HIGH RISK items
6. Verdict: **PASS** (zero BLOCKING, zero ADVISORY)
7. Asks: "May I write this LQA report to `production/localization/lqa-de-[date].md`?"
8. On approval, writes report
9. Outputs Phase 8 summary: locale cleared for release, report path, next step pointer

**Assertions**:
- [ ] `PASS` verdict in output
- [ ] Cultural review noted as skipped with reason
- [ ] Overflow assessment shown with no BLOCKING or HIGH RISK items
- [ ] "May I write" fires before report is written
- [ ] Summary includes "Include the report path in /gate-check release" pointer

**Case Verdict**: PASS

---

### Case 2: Failure — Blocking Placeholder Mismatch
**Fixture**:
- `assets/data/strings/strings-ja.json` exists
- One key has `{playerName}` in source but the translated value omits it
- Another key has a stale marker (`"status": "stale"`)
- Review mode: `lean`
- Argument: `ja`

**Expected behavior**:
1. Automated check spawned — returns two BLOCKING findings: LQA-001 (missing placeholder), LQA-002 (stale marker)
2. Verdict: **FAIL** — 2 BLOCKING issues
3. Asks to write LQA report (FAIL verdict recorded in report)
4. Phase 8 summary instructs: return to translator with error details / run `/l10n-sync`
5. Instructs re-run after fixing

**Assertions**:
- [ ] `FAIL` verdict in output
- [ ] Both BLOCKING findings listed with IDs and severity
- [ ] Report write prompt fires even for FAIL verdict
- [ ] Next step includes `/l10n-sync` pointer for stale entries
- [ ] Re-run instruction present

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Full Review Mode Triggers Cultural Phase
**Fixture**:
- `assets/data/strings/strings-ko.json` exists (all keys translated, no automated failures)
- Review mode argument: `--review full`
- Prior cultural review file exists at `production/localization/cultural-review-[date].md` with one BLOCKING item
- Argument: `ko --review full`

**Expected behavior**:
1. Review mode resolved to `full`
2. Automated checks pass
3. Cultural review phase NOT skipped — spawns `localization-lead`
4. Cultural review returns FAIL (unresolved BLOCKING item from prior review)
5. Verdict becomes FAIL (or PASS WITH CONDITIONS if treated as advisory — per spec, BLOCKING means FAIL)
6. Report includes Cultural Review Results section (not "Skipped")

**Assertions**:
- [ ] Cultural review subagent spawned in `full` mode
- [ ] Cultural findings appear in report table
- [ ] Verdict reflects cultural BLOCKING items
- [ ] Report does NOT show "Skipped" for cultural review section

**Case Verdict**: PASS

---

### Case 4: Edge Case — Locale File Not Found
**Fixture**:
- `assets/data/strings/strings-pt.json` does not exist
- Argument: `pt`

**Expected behavior**:
1. Reads source table successfully
2. Attempts to read `strings-pt.json` — not found
3. Outputs: "No translation file found for locale `pt`. Run `/l10n-integrate import pt [path]` first."
4. Stops cleanly

**Assertions**:
- [ ] Correct error message with locale code and next-step command
- [ ] Skill stops without spawning any subagents
- [ ] No crash or unhandled exception

**Case Verdict**: PASS

---

### Case 5: Protocol — LQA Report Write Approval
**Fixture**:
- All automated checks complete (any verdict)
- All phases produce findings

**Expected behavior**:
1. Full verdict compiled from all phases
2. Verdict report presented in conversation (or described) before write prompt
3. "May I write this LQA report to `production/localization/lqa-[locale]-[date].md`?" fires
4. No report written without approval

**Assertions**:
- [ ] Uses "May I write" before writing LQA report
- [ ] Verdict and findings presented before approval prompt
- [ ] No auto-write of report file

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- UI overflow assessment is explicitly approximate — HIGH RISK items flagged at >130% length without character limits are advisory and require in-engine verification. The spec cannot test whether the engine walkthrough was actually performed.
- The sign-off checklist in the report template ("All BLOCKING findings resolved", "HIGH RISK overflow items verified in-engine", "Producer approves shipping") is a human-action checklist and cannot be statically verified.
- In `lean`/`solo` modes, the cultural review section must explicitly note it was skipped — this is a reportable compliance check but requires runtime verification of the written file's content.
