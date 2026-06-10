---
name: localization-integrate
description: "Mid-pipeline localization skill. Export mode: extract strings, generate translator brief, and call string freeze. Import mode: validate and integrate returned translations into the project."
argument-hint: "[export|import locale path-to-translation-file|freeze lift] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Parse Arguments

- `export` → extract strings for translators (Phase 2A)
- `import [locale] [path]` → integrate returned translations (Phase 2B)
  - `locale`: locale code, e.g. `ja`, `de`, `fr`
  - `path`: path to the received translation file
- `freeze lift` → lift an active string freeze (Phase 2C)
- No argument → use `AskUserQuestion` to ask which mode

---

## Phase 2A: Export Mode

### Step 1 — Check Prerequisites

Read `assets/data/strings/strings-en.json`. If it does not exist:
> "No string table found. Run `/localization-prepare` first to extract strings from source code."
Stop.

Run a quick coverage check — grep `src/` for hardcoded strings (non-`tr()` user-facing text).
If found, warn:
> "⚠️ Hardcoded strings detected in source code. Run `/localization-prepare wrap` before
> exporting — translators will not receive these strings."
Continue regardless (user may know).

### Step 2 — Check String Freeze Status

Read `production/localization/freeze-status.md` if it exists.

- If already frozen: note the freeze date. Warn if any strings were added after freeze:
  > "⚠️ String freeze is ACTIVE (called [date]). [N] strings were added after freeze.
  > These are freeze violations — translators will receive a moving target. Resolve
  > freeze violations before exporting, or lift the freeze first."
- If not frozen: freeze will be called at the end of export (Step 4).

### Step 3 — Generate Translator Brief

Spawn `localization-lead` via Task:

```
Generate a translator brief for this project.

Read:
- assets/data/strings/strings-en.json — the full source string table
- design/gdd/game-concept.md — game overview, tone, setting, character names
- design/narrative/ — any character or lore documents (if they exist)

Produce a translator brief with these sections:
1. Game overview (2–3 paragraphs: genre, tone, audience)
2. Tone and voice (player address, formality, profanity policy, humour style)
3. Character glossary (name, role, personality, translation notes)
4. World/mechanic glossary (term, meaning, do-not-translate list)
5. Placeholder reference (each {variable} and what it represents)
6. Character limits (list all keys marked with a character limit in their context field)
7. Delivery format (JSON, same schema as strings-en.json)

Return the brief as a Markdown document ready to send to translators.
```

Present the brief to the user. Ask: "May I write this translator brief to `production/localization/translator-brief-[date].md`?"

### Step 4 — Call String Freeze

Ask: "Call string freeze now to lock the source table before translation begins?"

If yes:
- Create/update `production/localization/freeze-status.md`:

```markdown
# String Freeze Status

**Status**: ACTIVE
**Called**: [date]
**Total strings at freeze**: [N]

## Post-Freeze Changes
[Populated automatically by /localization-prepare wrap and /localization-sync]
```

### Step 5 — Export Summary

```
Localization Integrate — Export COMPLETE
=========================================
String table: assets/data/strings/strings-en.json ([N] strings)
Translator brief: production/localization/translator-brief-[date].md
String freeze: ACTIVE (called [date]) / Not called

What to send to translators:
1. assets/data/strings/strings-en.json — the source string table
2. production/localization/translator-brief-[date].md — context and guidelines
3. Expected delivery format: JSON, same schema as strings-en.json, filename: strings-[locale].json

Next steps:
- When translations arrive: /localization-integrate import [locale] [path]
- To check freeze status or violations: /localization-sync
```

---

## Phase 2B: Import Mode

Requires: `locale` code and `path` to the received translation file.

### Step 1 — Read and Validate Translation File

Read the received translation file at `[path]`. Read `assets/data/strings/strings-en.json`.

Spawn `localization-specialist` via Task:

```
Validate a received translation file before integrating it.

Source table: assets/data/strings/strings-en.json
Received translation: [path] (locale: [locale])

Check for:
1. Missing keys — key exists in source but not in the translation
2. Extra keys — key exists in translation but not in source (orphaned; flag for removal)
3. Placeholder mismatches — source has {variable} but translation is missing it or adds extras
4. Empty values — translated value is empty or whitespace
5. Schema violations — entries that don't match the expected JSON structure
6. Character limit violations — translated string exceeds the character limit noted in context

Report:
- PASS — no issues found, safe to integrate
- PASS WITH WARNINGS — minor issues (extra keys, advisory length warnings); list them
- FAIL — blocking issues (missing keys, placeholder mismatches); list all blocking items

Do not write any files. Report only.
```

Present the validation result.

If FAIL: stop and surface the blocking issues. Ask the user to return the file to the
translator with the error report.

If PASS or PASS WITH WARNINGS: continue.

### Step 2 — Preview Integration

Show the user what will be written:
> "I will write the validated translation to `assets/data/strings/strings-[locale].json`.
> This will create the file (or overwrite if it already exists).
> [N] strings will be imported. [N] warnings noted."

Ask: "May I write `assets/data/strings/strings-[locale].json`?"

### Step 3 — Write Translation File

Write the cleaned translation to `assets/data/strings/strings-[locale].json`.
If there were extra/orphaned keys from validation: strip them before writing.

### Step 4 — Integration Summary

```
Localization Integrate — Import COMPLETE
=========================================
Locale: [locale]
Strings imported: [N]
Warnings: [N] (list them)
Output: assets/data/strings/strings-[locale].json

Next steps:
- /localization-qa — run LQA pass for [locale] before this locale ships
- /localization-sync status — check overall coverage across all locales
```

---

## Phase 2C: Freeze Lift Mode

*Only reached when `freeze lift` argument was passed.*

### Step 1 — Check Freeze Status

Read `production/localization/freeze-status.md`.

If the file does not exist or Status is not ACTIVE:
> "No active string freeze found. Nothing to lift."
Stop.

### Step 2 — Warn and Confirm

Display the freeze record (called date, total strings at freeze, any post-freeze changes listed).

Warn:
> "⚠️ Lifting the string freeze means:
> - Translators will be working from an unstable source table
> - Any new strings added before re-freeze will need a new export brief
> - Previously delivered translations may no longer be accurate for changed strings
>
> Only lift if you need to make source text changes that cannot wait for the next translation cycle."

Ask: "Why are you lifting the freeze? (This reason will be recorded in the freeze log.)"

### Step 3 — Update Freeze Status

Ask: "May I update `production/localization/freeze-status.md` to record the lift?"

If yes, update the file:
- Change `**Status**: ACTIVE` → `**Status**: LIFTED`
- Add a `**Lifted**: [date]` line after the Called line
- Append to `## Post-Freeze Changes`:

```
### Freeze Lifted — [date]
Reason: [user-provided reason]
```

### Step 4 — Summary

```
String freeze LIFTED — [date]
================================
Freeze was active since: [original called date]
Lift reason: [reason]

Next steps:
- Make source text changes in src/ as needed
- Run /localization-prepare wrap if new strings are added
- When changes are complete: run /localization-integrate export to re-freeze and send to translators
- Run /localization-sync to flag any translations that are now stale
```

---

## Collaborative Protocol

- Never overwrite the source (en) string table — export is read-only on source
- Never write a translation file without running validation first (Phase 2B Step 1)
- Never skip showing the translator brief before asking to write it
- Freeze violations must be surfaced — never silently ignore them
- Freeze lift is irreversible via skill — user must manually reset Status to ACTIVE if lift was accidental
