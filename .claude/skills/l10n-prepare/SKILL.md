---
name: localization-prepare
description: "First stage of the localization pipeline: scan source for hardcoded strings, scaffold the string table structure if needed, and wrap strings in tr() calls. Run once before any translation work begins."
argument-hint: "[scan|wrap|scaffold] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Parse Arguments

- `scan` — find hardcoded strings only (read-only, no changes)
- `wrap` — scan + propose tr() wrapping + update string table
- `scaffold` — set up the string table directory structure for a new project
- No argument → run `scan` by default

---

## Phase 2: Read Project Context

Read:
- `.claude/docs/technical-preferences.md` — engine type (Godot/Unity/Unreal)
- `assets/data/strings/` — check if string table already exists
- `src/` — source code directory

Determine the engine's localization function:
| Engine | Function |
|--------|----------|
| Godot 4 | `tr("KEY")` |
| Unity | locale table lookup (Unity Localization package) |
| Unreal | `LOCTEXT()` / `NSLOCTEXT()` |

Store as `[LOC_FUNC]`.

---

## Phase 3A: Scan Mode

Spawn `localization-specialist` via Task:

```
Scan the source code in src/ for hardcoded user-facing strings that are not
wrapped in [LOC_FUNC].

Search for:
1. String literals in UI code not wrapped in [LOC_FUNC]
   - In Godot: look for .text = "...", label.set_text("..."), Button text properties
   - Exclude: code comments, debug prints, internal identifiers, file paths, enum names
2. String concatenations that should be parameterized (e.g., "You have " + str(count) + " parts")
3. Positional placeholders (%s, %d) instead of named ones ({playerName})
4. Date/time/number formatting without locale-aware calls

For each finding, report:
- File path and line number
- The hardcoded string
- Suggested string key (following: category.subcategory.description convention)
- Suggested context annotation (where it appears, character limit if constrained, placeholder meanings)

Read-only — do not modify any files. Report findings only.
Group results by: UI code / Dialogue / System messages / Other
```

Present the scan report to the user.

If no hardcoded strings found:
> "Scan complete — no hardcoded strings found. Either the project is already
> localized or source code has not been written yet."

If findings exist and mode is `scan`: stop here (read-only).
If mode is `wrap`: continue to Phase 4.

---

## Phase 3B: Scaffold Mode

Check whether `assets/data/strings/` exists and contains a source string table.

If it already exists:
> "`assets/data/strings/` already exists. Use `/localization-prepare wrap` to add
> new strings to the existing table, or `/localization-sync` to check for stale entries."
Stop.

If it does not exist, present the proposed structure:

```
assets/data/strings/
├── strings-en.json        ← source (English) string table
└── strings-[locale].json  ← one file per supported locale (created when translations arrive)
```

String table schema:
```json
{
  "key": {
    "source": "English text here",
    "context": "Where it appears, character limit, placeholder meanings",
    "status": "source"
  }
}
```

Ask: "May I create `assets/data/strings/strings-en.json` with this structure?"

If yes, create the scaffold file with a header comment entry only. Verdict: **COMPLETE** — string table scaffolded.

---

## Phase 4: Wrap Mode

Requires Phase 3A scan to have been run first (findings available).

Show the user the proposed changes:

```
Proposed changes:
- [N] strings to wrap in [LOC_FUNC] across [M] files
- [N] new keys to add to assets/data/strings/strings-en.json

Files to be modified:
- src/[file1] — [N] strings
- src/[file2] — [N] strings
- assets/data/strings/strings-en.json — [N] new entries
```

Ask: "May I proceed with wrapping these strings? I'll show each file's diff before writing."

If yes, spawn `localization-specialist` via Task for each file:

```
Wrap the following hardcoded strings in [LOC_FUNC] in [filepath]:

[list of findings for this file with suggested keys]

Rules:
- Use tr("KEY") syntax for Godot / equivalent for other engines
- Do not change any logic, only wrap the string literals
- If a string uses concatenation, convert to a parameterized key with named placeholders
- Show the full diff for this file before proposing any write

Read the current file content first, then show the proposed diff.
Do not write the file — return the diff for review.
```

Collect all diffs. Present each one and ask: "May I write this change to [filepath]?"

After all source files are approved, spawn `localization-specialist` via Task:

```
Generate new string table entries for these keys:

[list of approved keys with their source text and context]

Format each entry as:
{
  "key.name": {
    "source": "English text",
    "context": "[where it appears], [char limit if known], [placeholder meanings]",
    "status": "source"
  }
}

Read assets/data/strings/strings-en.json first.
Return the entries to ADD (do not return the full file — return only the new entries).
```

Ask: "May I add these [N] entries to `assets/data/strings/strings-en.json`?"

If yes, append the entries to the existing JSON (do not overwrite).

---

## Phase 5: Summary

```
Localization Prepare — COMPLETE
================================
Mode: [scan / wrap / scaffold]
Hardcoded strings found: [N]
Strings wrapped: [N]  (wrap mode only)
New string table entries: [N]  (wrap mode only)

[If strings remain unwrapped — scan-only mode or user declined:]
Remaining hardcoded strings: [N] — run /localization-prepare wrap to address

Next steps:
- /localization-integrate export — extract final strings and prepare for translators
- /localization-integrate export — call string freeze before sending strings to translators
- /localization-sync — if source text changes after this point
```

---

## Collaborative Protocol

- Never modify source files without showing the diff and receiving approval per file
- Never overwrite the string table — always append new entries
- Exclude from scan: debug output, file paths, enum/constant names, internal identifiers
- If unsure whether a string is user-facing, flag it rather than silently skipping
