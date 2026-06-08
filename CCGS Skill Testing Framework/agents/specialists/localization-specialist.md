# Agent Test Spec: localization-specialist

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-06-08

## Agent Summary

Domain: Hands-on localization execution — wrapping strings in `tr()` calls, importing and validating translations, running LQA (overflow, tone, placeholder, cultural checks), syncing string tables when source text changes. Works under `localization-lead` direction.

Does NOT own: pipeline architecture (`localization-lead`), language support scope (`producer`), UI layout for overflow (`ux-designer` + `ui-programmer`), actual translations (external translators), source text meaning (`writer`).

**Domain**: localization implementation across `src/` and locale resource files  
**Escalates to**: `localization-lead` for architecture; `producer` for language scope; `ux-designer` + `ui-programmer` for overflow layout  
**Delegates to**: none — hands-on implementer

---

## Static Assertions (Structural)

- [ ] `description:` present and execution-focused (references tr() wrapping, LQA, string table sync)
- [ ] `tools` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is Sonnet
- [ ] Agent explicitly defers architecture decisions to `localization-lead`

---

## Test Cases

### Case 1: In-domain request — string wrapping

**Input:** "Wrap all hardcoded UI strings in `src/ui/` in tr() calls and generate corresponding string table entries."

**Expected behavior:**
- Scans `src/ui/` for hardcoded user-facing strings (not log messages or internal identifiers)
- Generates hierarchical dot-notation keys (e.g., `ui.menu.main.play_button`)
- Wraps each string in `tr("KEY")` (Godot) or equivalent for the configured engine
- Generates source string table entries with context annotations (location, max length, placeholder meanings)
- Shows proposed changes before writing. Asks "May I write these changes to [filepath(s)]?"
- Does NOT change narrative text meaning or UI layout

### Case 2: Out-of-domain redirect — pipeline architecture

**Input:** "Should we use .po files or a custom JSON format for our translation strings?"

**Expected behavior:**
- Does NOT make the architecture decision
- Explicitly escalates to `localization-lead` as owner of pipeline architecture
- May describe trade-offs (portability, tooling support) to inform the lead's decision, but does not choose

### Case 3: LQA pass — overflow and placeholder check

**Input:** "German translations have been delivered. Run an LQA check."

**Expected behavior:**
- Validates all placeholder references are preserved (`{playerName}` still present in German strings)
- Checks for UI overflow by comparing German string lengths against context-annotated max lengths
- Flags encoding issues (mojibake, missing font coverage for special characters)
- Reports by key: PASS / OVERFLOW / MISSING_PLACEHOLDER / ENCODING_ISSUE
- Does NOT auto-fix overflow by truncating text — escalates layout changes to `ux-designer` + `ui-programmer`

### Case 4: String table sync after source change

**Input:** "The tutorial button text changed from 'Start Tutorial' to 'Begin Tutorial'. Update the string table."

**Expected behavior:**
- Identifies the affected key(s) in the source string table
- Updates the English source string to the new value
- Marks all translated versions of that key as stale (adds stale marker or removes pending re-translation)
- Does NOT rename the key — keys are stable once translated
- Does NOT rewrite the translation itself
- Generates a re-translation request summary: affected key, old text, new text

### Case 5: Context pass — engine-specific import

**Input:** Context: "Engine is Godot 4.6. Translations are in .po format. Locale directory is res://locales/." Request: "Import the French translation file fr.po."

**Expected behavior:**
- References all context: Godot 4.6, .po format, res://locales/ path
- Validates fr.po before import (missing keys, placeholder mismatches vs. source)
- Checks `docs/engine-reference/` for Godot 4.6 localization API before suggesting import steps
- Asks "May I write this to res://locales/fr.po?" before writing

---

## Protocol Compliance

- [ ] Stays within declared domain (string wrapping, LQA, import, sync)
- [ ] Defers pipeline architecture decisions to `localization-lead`
- [ ] Defers language scope decisions to `producer`
- [ ] Defers UI overflow layout fixes to `ux-designer` + `ui-programmer`
- [ ] Never rewrites source text meaning (`writer` owns that)
- [ ] Uses stable dot-notation key conventions — never renames keys after translation
- [ ] Uses named placeholders, never positional
- [ ] Uses "May I write" before file changes

---

## Coverage Notes

- Case 3 (LQA) tests that the agent reports overflow rather than auto-fixing it
- Case 4 (sync) tests stale marking rather than direct translation modification
- Case 5 verifies the agent checks `docs/engine-reference/` before using localization APIs
- No gate IDs assigned
