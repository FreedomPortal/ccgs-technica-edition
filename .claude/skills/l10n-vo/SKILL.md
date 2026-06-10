---
name: l10n-vo
description: Voice-over pipeline for localization. Subcommands: scan (recording manifest by character), script [locale] (per-character recording scripts with direction notes), validate [locale] (audio file existence + naming check), integrate [locale] (verify VO file references in code).
argument-hint: "[scan | script locale | validate locale | integrate locale]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
model: sonnet
---

# /l10n-vo [subcommand] [locale?]

**Purpose**: Manage the voice-over pipeline for a localized game. Handles recording manifests,
per-locale recording scripts with director notes, audio file validation, and VO integration
verification. Works on top of the string table established by `/l10n-prepare`.

**Prerequisites**: String table must exist at `assets/data/strings/strings-en.json`. VO keys
must follow the convention `vo.[character].[line_id]` in the string table to be detected.

---

## Subcommands

| Subcommand | Args | Purpose |
|-----------|------|---------|
| `scan` | — | Generate recording manifest grouped by character |
| `script` | `[locale]` | Generate per-character recording scripts with director notes |
| `validate` | `[locale]` | Check audio files exist, are correctly named, and are correct format |
| `integrate` | `[locale]` | Verify VO file references in src/ code; flag hardcoded locale paths |

---

## Phase 1: Parse Subcommand

Read the argument. If no subcommand or unrecognised argument:

```
Usage: /l10n-vo [subcommand] [locale?]

  scan              — recording manifest by character (all locales)
  script [locale]   — per-character recording scripts with director notes
  validate [locale] — check audio files exist, correctly named, correct format
  integrate [locale]— verify VO references in code; flag hardcoded paths

Examples:
  /l10n-vo scan
  /l10n-vo script ja
  /l10n-vo validate fr
  /l10n-vo integrate de
```

---

## Subcommand: scan

Spawn `localization-specialist` via Task:

```
VO Pipeline — Recording Manifest Scan

Read assets/data/strings/strings-en.json.
Identify all keys matching pattern: vo.[character].[line_id]

For each character found, list:
  - Character name (from the key segment)
  - Total VO lines assigned
  - For each locale in assets/data/strings/: count how many VO keys have a corresponding
    audio file at assets/audio/vo/[locale]/[character]/[key_as_filename].ogg
    (key format: dots replaced with underscores — e.g. vo.rival_1.greeting_01 → vo_rival_1_greeting_01.ogg)

Output format:

CHARACTER: [name]
  Lines: [N] total
  ┌─ Locale ──┬─ Recorded ──┬─ Missing ─┐
  │ en        │ [N]         │ [N]       │
  │ ja        │ [N]         │ [N]       │
  └───────────┴─────────────┴───────────┘

  Missing files (en):
    - vo_[character]_[line].ogg
```

If no `vo.*` keys found: "No VO keys detected in string table. VO keys must follow pattern `vo.[character].[line_id]` to be tracked by this pipeline."

---

## Subcommand: script [locale]

Ask: "Which character(s) should this script cover? (all / [character name])"

Spawn `localization-specialist` via Task:

```
VO Pipeline — Recording Script Generation

Locale: [locale]
Character filter: [all / name]

Read:
- assets/data/strings/strings-en.json — source lines
- assets/data/strings/strings-[locale].json — translated lines (if locale != en)
- design/narrative/ — any character sheets or dialogue notes present (for director notes)

For each VO key matching the character filter:

OUTPUT FORMAT:

=== [CHARACTER NAME] ===
Recording Script — [locale] — [date]

LINE [N]: [key]
  Source (en):    "[source text]"
  [locale] text:  "[translated text]" (or [NOT TRANSLATED — use source] if locale=en or no translation found)
  Audio filename: [key_underscored].ogg
  Emotion:        [derive from key suffix if available: greeting/angry/victory/defeat/idle — otherwise UNSPECIFIED]
  Director note:  [any relevant note from character sheet, or "No direction notes available"]
  Pronunciation:  [flag any proper nouns, invented words, or technical terms for pronunciation guide]
```

Output as a formatted markdown file preview. Ask: "May I write this recording script to `production/localization/vo-scripts/[locale]/[character]-script-[date].md`?"

---

## Subcommand: validate [locale]

Spawn `localization-specialist` via Task:

```
VO Pipeline — Audio File Validation

Locale: [locale]
Expected audio directory: assets/audio/vo/[locale]/

For each VO key in assets/data/strings/strings-en.json (pattern: vo.[character].[line_id]):

1. EXISTENCE CHECK
   Expected filename: [key with dots replaced by underscores].ogg
   Expected path: assets/audio/vo/[locale]/[character]/[filename]
   Status: FOUND / MISSING

2. NAMING CHECK (for FOUND files only)
   Confirm filename exactly matches the expected pattern (no spaces, no uppercase, no extra suffixes)
   Flag: CORRECT / NAMING_ERROR (show actual vs expected)

3. FORMAT CHECK (for FOUND files only)
   Extension must be .ogg or .wav
   Flag: CORRECT / FORMAT_ERROR (show actual extension)

Output summary:

VO Validation — [locale] — [date]
===================================
Total VO lines: [N]
Found:          [N]
Missing:        [N]
Naming errors:  [N]
Format errors:  [N]

MISSING:
  [list of missing files with expected paths]

NAMING ERRORS:
  [actual filename] → expected: [correct filename]

FORMAT ERRORS:
  [file] — found .[ext], expected .ogg or .wav
```

Verdict: **READY** (0 missing, 0 errors) / **CONCERNS** (naming/format errors only) / **NOT READY** (missing files)

---

## Subcommand: integrate [locale]

Spawn `localization-specialist` via Task:

```
VO Pipeline — Code Integration Verification

Locale: [locale]

Search src/ for any references to audio file paths containing "vo/" or "voice/".

For each reference found:

1. HARDCODED LOCALE PATH
   Flag any path that contains a hardcoded locale code (e.g. "assets/audio/vo/en/", "/ja/")
   These must use a dynamic locale resolver instead.
   Severity: HIGH

2. KEY-BASED REFERENCE CHECK
   If the reference uses a string key (e.g. AudioServer.load(tr("vo.rival_1.greeting_01"))),
   verify the key exists in strings-en.json.
   Status: KEY_FOUND / KEY_MISSING

3. FILE EXISTENCE CROSSCHECK
   For each resolved path found in code, verify the file exists in assets/audio/vo/[locale]/
   Status: FILE_FOUND / FILE_MISSING

Output:

VO Integration Check — [locale] — [date]
==========================================
References scanned: [N]

HIGH SEVERITY — Hardcoded locale paths:
  [file:line] "[hardcoded path]" — replace with dynamic locale resolver

KEY MISSING (string key referenced in code but not in string table):
  [file:line] "[key]"

FILE MISSING (resolved path does not exist on disk):
  [file:line] "[path]"

CLEAN: [N] references verified correctly
```

Verdict: **READY** (no HIGH, no missing) / **CONCERNS** (missing files only) / **NOT READY** (hardcoded paths or missing keys)

---

## Collaborative Protocol

- Never rename or move audio files without explicit user approval
- Recording scripts are read-only exports — they do not modify string tables
- Validation is non-destructive: reports only, no file changes
- Integration check is read-only: reports hardcoded paths but does not auto-fix
