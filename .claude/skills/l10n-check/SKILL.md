---
name: l10n-check
description: "Localization status check. Reads localization intent and current pipeline stage; reports what l10n artifacts exist, what's missing for this stage, and what to do next. Runs automatically at session start when intent is YES. Also the skill to run after /start declares intent."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: haiku
---

# /l10n-check — Localization Status Check

Read-only status snapshot. No files written.

---

## Phase 1: Read Intent

Read `production/localization/intent.md`.

**If the file does not exist:**
```
Localization intent not declared.
Run /start or answer the l10n question there to capture intent.
All /l10n-* skills are available immediately if you want to begin — minimum
requirement is source code in src/ for /l10n-i18n and /l10n-prepare.
```
Stop.

**If Status: NO:**
```
Localization intent: NO — l10n pipeline skipped by choice.
To change this, edit production/localization/intent.md Status field.
```
Stop.

**If Status: LATER:**
```
Localization intent: LATER — deferred decision.
Reminder: entering Production without strings extracted means retrofitting mid-sprint.
When ready to commit: edit production/localization/intent.md Status to YES and
run /l10n-check again to see what's needed.
```
Stop.

**If Status: YES:** continue. Read:
- `**Target locales**:` field — parse into locale list
- `**Stage at declaration**:` field
- Current stage: read `production/stage.txt`

---

## Phase 2: Collect Artifact Status

Check each artifact. Mark ✅ DONE, ⚠️ MISSING, or ➡️ NOT YET (correct for this stage).

| Artifact | Path | Check |
|----------|------|-------|
| String table scaffolded | `assets/data/strings/strings-en.json` | Glob |
| String table has entries | same file | Read + count keys |
| i18n audit run | `production/localization/i18n-audit-*.md` | Glob |
| Cultural review run | `production/localization/cultural-review-*.md` | Glob |
| Translator brief exists | `production/localization/translator-brief-*.md` | Glob |
| Screenshot checklist exists | `production/localization/screenshot-checklist-*.md` | Glob |
| String freeze status | `production/localization/freeze-status.md` | Read Status field |
| LQA pass per locale | `production/localization/lqa-[locale]-*.md` (per locale in intent) | Glob per locale |
| RTL check (RTL locales only) | `production/localization/rtl-check-[locale]-*.md` | Glob (ar/he/fa/ur only) |

---

## Phase 3: Stage-Aware Report

Map current stage to expected l10n progress. Surface gaps as OVERDUE or UPCOMING.

```
Localization Status — [date]
==============================
Intent: YES  |  Locales: [list]
Current stage: [stage]

ARTIFACTS
─────────────────────────────────────────────────────
[✅/⚠️/➡️] String table scaffolded
[✅/⚠️/➡️] String table entries ([N] keys)
[✅/⚠️/➡️] i18n audit (production/localization/i18n-audit-*.md)
[✅/⚠️/➡️] Translator brief
[✅/⚠️/➡️] Screenshot checklist
[✅/⚠️/➡️] String freeze: [ACTIVE / not called / LIFTED]
[✅/⚠️/➡️] LQA — [locale1]: [PASS / FAIL / MISSING]
[✅/⚠️/➡️] LQA — [locale2]: ...
[✅/⚠️/➡️] RTL check — [rtl-locale]: ... (if applicable)
─────────────────────────────────────────────────────

OVERDUE FOR [stage] STAGE
[List items that should exist by now but don't]

UPCOMING (not yet required)
[List items that become relevant in later stages]

NEXT STEPS
[Ordered list: most urgent first]
```

Stage expectations:

| Stage | Should exist | Advisory |
|-------|-------------|----------|
| Concept / Systems Design | intent.md | Nothing else yet |
| Technical Setup | i18n audit OR intent noted | Consider /l10n-i18n before architecture |
| Pre-Production / Vertical Slice | string table scaffolded, i18n audit done | /l10n-prepare scaffold |
| Production | string table has entries, strings wrapped | /l10n-prepare wrap → /l10n-integrate export |
| Polish | freeze active, translator brief sent, translations importing | /l10n-sync, /l10n-qa per locale |
| Release | LQA PASS for all declared locales | /l10n-qa [locale] for any missing |

---

## Collaborative Protocol

- Read-only — never writes files
- Surfaces OVERDUE items clearly; upcoming items less prominently
- If a locale in the intent list has no LQA report and stage is Release: mark as BLOCKING
- Does not launch any l10n skill — reports and stops; user runs the recommended skill
