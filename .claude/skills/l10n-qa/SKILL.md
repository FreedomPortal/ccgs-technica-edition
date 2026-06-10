---
name: localization-qa
description: "Dedicated LQA pass for a locale after translations are integrated. Checks completeness, placeholder accuracy, UI overflow, tone, cultural issues, and produces a per-locale verdict. Required before any locale ships."
argument-hint: "[locale] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Parse Arguments

If `[locale]` is provided, use it. Otherwise use `AskUserQuestion`:
- Prompt: "Which locale would you like to QA?"
- Options: [read `assets/data/strings/` and list all strings-[locale].json files found, excluding en]

---

## Phase 2: Read Context

Read:
- `assets/data/strings/strings-en.json` — source table
- `assets/data/strings/strings-[locale].json` — target translation
- `production/localization/cultural-review-[date].md` — most recent cultural review (if exists)
- `design/gdd/` — game screens and UI elements (for overflow context)

If `strings-[locale].json` does not exist:
> "No translation file found for locale `[locale]`. Run `/localization-integrate import [locale] [path]` first."
Stop.

---

## Phase 3: Automated Checks

Spawn `localization-specialist` via Task:

```
Run an automated LQA check on the [locale] translation.

Source: assets/data/strings/strings-en.json
Translation: assets/data/strings/strings-[locale].json

Check each translated string for:

1. COMPLETENESS
   - Every key in source has a translation
   - No translation is empty or whitespace-only

2. PLACEHOLDER ACCURACY
   - Every {variable} in the source appears in the translation
   - No extra {variables} added that don't exist in source
   - {variable} names are unchanged (not translated)

3. CHARACTER LIMIT VIOLATIONS
   - Read the "context" field of each source entry for character limits
   - Flag any translation that exceeds its stated limit

4. ENCODING
   - Flag any strings containing replacement characters (U+FFFD) that indicate encoding errors
   - Flag any strings using ASCII approximations of characters that should be Unicode
     (e.g., "..." instead of "…", "--" instead of "–")

5. STALE MARKERS
   - Flag any entries with status: "stale" — these need re-translation

Report format:
| ID | Key | Check | Issue | Severity |
|----|-----|-------|-------|----------|
| LQA-001 | [key] | Placeholder | Missing {playerName} | BLOCKING |
| LQA-002 | [key] | Char limit | 45 chars, limit is 32 | BLOCKING |
| LQA-003 | [key] | Stale | Marked stale — needs re-translation | BLOCKING |
| LQA-004 | [key] | Encoding | Uses ASCII "..." instead of "…" | ADVISORY |

Severity: BLOCKING (must fix before locale ships) / ADVISORY (recommended fix) / NOTE (informational)

Do not write any files. Report only.
```

Present the automated check results.

---

## Phase 4: Cultural Review Check

**Review mode check** — apply before spawning:
- `solo` → skip. Note: "Cultural review skipped — Solo mode."
- `lean` → skip. Note: "Cultural review skipped — Lean mode."
- `full` → spawn as normal.

If full mode: spawn `localization-lead` via Task:

```
Review the [locale] translation for cultural appropriateness and localization quality.

Read:
- assets/data/strings/strings-en.json — source
- assets/data/strings/strings-[locale].json — translation
- production/localization/cultural-review-[date].md — prior cultural review findings (if exists)

Assess:
1. Are the BLOCKING items from the cultural review resolved in this translation?
2. Are there tone/register issues — strings that are too formal, too casual, or wrong
   for the game's established voice?
3. Are there idioms or expressions that translate literally but sound unnatural or
   carry unintended meaning in [locale]?
4. Are there culturally sensitive terms or references that were not flagged in the
   prior review?

Report findings using the same table format (ID, Key, Check, Issue, Severity).
Return: PASS / PASS WITH ADVISORY ITEMS / FAIL (BLOCKING items unresolved)
```

---

## Phase 5: UI Overflow Assessment

Note: true overflow can only be confirmed in-engine with the game running. This phase
identifies HIGH RISK strings that are likely to overflow based on character counts and
known UI constraints.

Spawn `localization-specialist` via Task:

```
Identify high-risk UI overflow candidates for [locale].

Read:
- assets/data/strings/strings-en.json — source with context fields (character limits)
- assets/data/strings/strings-[locale].json — translation

For each string in a UI context (keys starting with "ui."):
- Compare translated length to English length
- Flag strings that are >130% of English length as HIGH RISK
- Flag strings that exceed their character limit (from context field) as BLOCKING
- Note the screen/element from the context field

Return:
BLOCKING: translations that exceed stated character limits
HIGH RISK: translations >130% of English length without a stated limit

Do not flag dialogue or narrative strings — only UI strings are layout-constrained.
```

Present results. Remind the user that HIGH RISK items must be verified in-engine.

---

## Phase 6: Verdict

Compile all findings from Phases 3, 4, and 5. Tally:
- BLOCKING issues: [N]
- ADVISORY issues: [N]

Determine verdict:
- **PASS** — zero BLOCKING issues
- **PASS WITH CONDITIONS** — zero BLOCKING, one or more ADVISORY (list them)
- **FAIL** — one or more BLOCKING issues (list all)

Generate a verdict report.

---

## Phase 7: Write LQA Report

Ask: "May I write this LQA report to `production/localization/lqa-[locale]-[date].md`?"

If yes, write:

```markdown
# Localization QA Report — [locale]

**Date**: [date]
**Locale**: [locale]
**Verdict**: PASS / PASS WITH CONDITIONS / FAIL

## Automated Check Results
| ID | Key | Check | Issue | Severity |
|----|-----|-------|-------|----------|
[findings from Phase 3]

## Cultural Review Results
[findings from Phase 4, or "Skipped — Lean/Solo mode"]

## UI Overflow Assessment
[findings from Phase 5]

## Conditions (if PASS WITH CONDITIONS)
- [Condition — must resolve before locale ships]

## Sign-Off Checklist
- [ ] All BLOCKING findings resolved
- [ ] HIGH RISK overflow items verified in-engine
- [ ] Producer approves shipping [locale]

## Gate Integration
This report is required by the Polish → Release gate for every shipping locale.
A FAIL verdict blocks this locale from release. Other locales are unaffected.
```

---

## Phase 8: Next Steps

```
Localization QA — [locale] — [PASS / PASS WITH CONDITIONS / FAIL]
===================================================================
BLOCKING issues: [N]
ADVISORY issues: [N]
Report: production/localization/lqa-[locale]-[date].md

[If PASS:]
This locale is cleared for release. Include the report path in /gate-check release.

[If PASS WITH CONDITIONS:]
Resolve conditions before release. Re-run /localization-qa [locale] after fixes.

[If FAIL:]
Fix all BLOCKING issues:
- Placeholder mismatches: return to translator with error details
- Character limit violations: request shorter translations or redesign UI element
- Stale entries: run /localization-sync to identify re-translation scope
Re-run /localization-qa [locale] after fixing.
```

---

## Collaborative Protocol

- Never skip the automated checks — they are a blocking gate, not advisory
- Never write the LQA report without asking first
- Overflow assessment in Phase 5 is approximate — always flag HIGH RISK items for
  in-engine verification, never report them as definitively passing or failing
- If cultural review is skipped (lean/solo): note explicitly in the report that
  cultural review was not performed for this locale
