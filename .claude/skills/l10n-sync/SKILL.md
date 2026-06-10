---
name: localization-sync
description: "Detects stale translations after source text changes, generates re-translation requests for affected keys, and updates stale markers in translation files. Run whenever English source strings are edited post-freeze."
argument-hint: "[status] [--locale [code]] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Parse Arguments

- `status` → generate coverage matrix and freeze status report only (Phase 2B); stop — does not run stale detection or mark files
- `--locale [code]` → sync a specific locale only (e.g. `--locale ja`)
- No argument → sync all locales found in `assets/data/strings/`

---

## Phase 2: Read String Tables

Read `assets/data/strings/strings-en.json` (source).

Glob `assets/data/strings/strings-*.json` — collect all locale files, excluding `strings-en.json`.

If `--locale` was specified, filter to that file only.

If no locale files exist:
> "No translation files found. Run `/localization-integrate import [locale] [path]`
> after receiving translations."
Stop.

---

## Phase 2B: Status Mode (read-only)

*Only reached when `status` argument was passed. Skip all other phases.*

Read `assets/data/strings/strings-en.json` (source). Count total keys.

Glob `assets/data/strings/strings-*.json` — collect all locale files.

For each locale file, count:
- `translated`: entries where `"status"` is absent or `"ok"`
- `stale`: entries where `"status": "stale"`
- `needs_translation`: entries where `"status": "needs_translation"` or value is empty
- `missing`: keys present in source but absent from locale file
- `coverage%`: `translated / total_source_keys * 100`

Read `production/localization/freeze-status.md` if it exists.

Output:

```
Localization Status — [date]
==============================
String freeze: ACTIVE (called [date]) / NOT ACTIVE

| Locale | Total | Translated | Stale | Needs Translation | Missing | Coverage |
|--------|-------|------------|-------|-------------------|---------|----------|
| ja     | [N]   | [N]        | [N]   | [N]               | [N]     | [N]%     |
| fr     | [N]   | [N]        | [N]   | [N]               | [N]     | [N]%     |

To update stale translations: /localization-sync
To run LQA on a locale:       /localization-qa [locale]
To check RTL support:         /localization-rtl [locale]
```

Stop — no further phases.

---

## Phase 3: Stale Detection

Spawn `localization-specialist` via Task:

```
Detect stale translations by comparing source strings against translated files.

Source: assets/data/strings/strings-en.json
Locale files: [list of locale files to check]

A translation is STALE when:
1. The "source" field in strings-en.json differs from the "source" field stored in the locale
   file for that key — meaning the English text changed after translation was delivered
2. The locale file has status: "stale" already set

A translation is MISSING when:
3. The key exists in strings-en.json but not in the locale file at all

A translation is ORPHANED when:
4. The key exists in the locale file but not in strings-en.json (source key was removed)

For each locale file, produce a sync report:

## Sync Report — [locale]
| ID | Key | Issue | English (current) | Translated value | Recommended action |
|----|-----|-------|-------------------|------------------|--------------------|
| SY-001 | [key] | STALE | "[current English]" | "[translation]" | Re-translate |
| SY-002 | [key] | MISSING | "[current English]" | — | Translate |
| SY-003 | [key] | ORPHANED | — | "[value]" | Remove from locale file |

Summary per locale:
- Stale: [N]
- Missing: [N]
- Orphaned: [N]
- Up to date: [N]

Do not write any files. Report only.
```

Present the sync report to the user.

---

## Phase 4: Freeze Violation Check

Read `production/localization/freeze-status.md` if it exists.

If Status is ACTIVE and stale/missing keys were found:
> "⚠️ String freeze is ACTIVE (called [date]). [N] keys have changed or were added
> after freeze. These are freeze violations.
>
> Options:
> A) Fix the English source strings back to their frozen values (revert the changes)
> B) Lift the freeze, re-translate affected strings, then re-call freeze before sending
>
> The current sync will mark affected keys as stale regardless — this is the correct state."

---

## Phase 5: Mark Stale Keys

Ask: "May I mark stale and missing keys in the locale translation files?"

This sets `"status": "stale"` on affected entries so that `/localization-qa` can
flag them as BLOCKING and `/localization-qa` can report them.

If yes, spawn `localization-specialist` via Task:

```
Update locale translation files to mark stale and missing keys.

For each locale file in: [list]
For each STALE key in the sync report:
  - Set "status": "stale" on that entry
  - Store the OLD translated value in a "previous_translation" field for translator reference
  - Store the NEW English source in a "new_source" field

For each MISSING key:
  - Add a new entry with: source from strings-en.json, "status": "needs_translation",
    empty "value": ""

For each ORPHANED key:
  - Do NOT remove them automatically — flag them with "status": "orphaned"

Show a diff of proposed changes for each locale file before writing.
Do not write until the user approves each file.
```

Collect diffs and present each one. Ask per file: "May I write these changes to `assets/data/strings/strings-[locale].json`?"

---

## Phase 6: Re-Translation Request

Ask: "Would you like to generate a re-translation request document to send to your translators?"

If yes, spawn `localization-specialist` via Task:

```
Generate a re-translation request document.

Read:
- assets/data/strings/strings-en.json — for context fields and current English text
- The sync report from this session

Produce a re-translation request document:

## Re-Translation Request — [game name] — [date]

### Summary
[N] strings require re-translation due to source text changes since the last delivery.

### Strings Requiring Re-Translation

| Key | Context | Previous English (translated from) | New English (translate from this) |
|-----|---------|-------------------------------------|-----------------------------------|
| [key] | [context from source table] | [old English] | [new English] |

### New Strings (not yet translated)

| Key | Context | English source |
|-----|---------|----------------|
| [key] | [context] | [source] |

### Keys to Remove (source removed)
The following keys are no longer in the game and should be removed from your
translation memory: [list of orphaned keys]

### Delivery Instructions
Return the updated strings in the same JSON format as the original delivery.
Only return changed/new keys — do not re-send unchanged strings.
```

Ask: "May I write this re-translation request to `production/localization/retranslation-request-[date].md`?"

---

## Phase 7: Update Freeze Record

If a re-translation request was generated and freeze is ACTIVE, append to
`production/localization/freeze-status.md` under `## Post-Freeze Changes`:

```
### Sync Run — [date]
- Stale: [N] keys
- Missing: [N] keys  
- Orphaned: [N] keys
- Re-translation request: production/localization/retranslation-request-[date].md
```

Ask: "May I append this sync record to `production/localization/freeze-status.md`?"

---

## Phase 8: Summary

```
Localization Sync — COMPLETE
==============================
Locales checked: [list]

[Per locale:]
  [locale]: [N] stale, [N] missing, [N] orphaned, [N] up to date

Stale markers written: [Y/N]
Re-translation request: [path / not generated]

Next steps:
- Send production/localization/retranslation-request-[date].md to translators
- When updated translations arrive: /localization-integrate import [locale] [path]
- After import: /localization-qa [locale] to re-validate the updated locale
```

---

## Collaborative Protocol

- Never auto-remove orphaned keys — flag them; user decides whether to remove
- Never write stale markers or the re-translation request without explicit approval per file
- Freeze violations must be surfaced prominently — source text changes during freeze
  are serious pipeline problems that affect translator workflow and cost
- The "previous_translation" field is important — translators use it for reference,
  so always preserve it when marking a key stale
