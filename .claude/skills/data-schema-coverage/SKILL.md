---
name: data-schema-coverage
description: "Audit game data files for schema completeness: extracts required fields per content type from GDDs, then checks each data file in assets/data/ for missing, null, or empty fields. Answers 'are all weapon/enemy/item definitions complete?' Optional --report writes audit to docs/. Optional --roadmap writes milestone-grouped data production plan to production/data-roadmap.md."
argument-hint: "[content-type] [--report] [--roadmap]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

When this skill is invoked:

## Parse Arguments

- **`[content-type]`** — optional. Scope audit to one content type (e.g., `weapons`,
  `enemies`, `items`, `abilities`, `quests`). Normalized to lowercase singular or plural.
  If absent → full audit across all discoverable content types.
- **`--report`** — optional. After the audit, offer to write the full report to
  `docs/data-schema-coverage-[YYYY-MM-DD].md`.
- **`--roadmap`** — optional. After the audit, offer to write a milestone-grouped data
  production plan to `production/data-roadmap.md`.

Store all flags for use in later phases.

---

## Phase 1: Discover Content Types

### 1a — Read systems index

Read `design/gdd/systems-index.md` if it exists.

Extract system names that are likely to own content data files — look for systems in
categories like: Items, Combat, Enemies, Progression, Abilities, Quests, Crafting,
Dialogue, Economy, Equipment.

### 1b — Scan data directory

Glob `assets/data/**/*` to find all files.

Group files by immediate subdirectory name — each subdirectory is treated as a
**content type** (e.g., `assets/data/weapons/` → content type: `weapons`).

File formats to process:
- **JSON** (`.json`)
- **YAML** (`.yaml`, `.yml`)
- **Godot resources** (`.tres`, `.res`) — text format, parseable as key=value
- **Unity assets** (`.asset`) — YAML-like serialization
- **CSV** (`.csv`) — first row is the schema (column headers)

Ignore: directories, `.import` files, binary files (`.png`, `.wav`, `.ogg`, etc.),
`README.md`, `.gitkeep`.

**If `assets/data/` is empty or missing:**
> "No data files found in `assets/data/`. Content may not yet be implemented. Run
> `/content-audit` to compare GDD-specified counts against implementation progress."

Record: for each content type, the list of files and their formats.

### 1c — Scope filter

If a `[content-type]` argument was passed, filter to only that type. If the argument
does not match any discovered subdirectory, check for partial matches (e.g., `weapon`
matches `weapons`). If no match, report:
> "No data files found for content type `[arg]` in `assets/data/`. Discovered types:
> [list]. Run without an argument for a full audit."

### 1d — Present scope to user

Show the discovered content types and file counts:
```
Discovered content types:
- weapons        → 12 files (.json)
- enemies        → 8 files (.json)
- abilities      → 20 files (.yaml)
- items          → 35 files (.json)
- quests         → 6 files (.yaml)
```

If a `[content-type]` argument was passed, confirm: "Scoping audit to `[type]` ([N] files)."

---

## Phase 2: Extract Required Fields from GDDs

For each content type in scope, find and read the corresponding GDD to extract the
required field contract.

### 2a — Locate the GDD

Try these paths in order:
1. `design/gdd/[content-type].md` (e.g., `design/gdd/weapons.md`)
2. `design/gdd/[singular-content-type].md` (e.g., `design/gdd/weapon.md`)
3. Grep `design/gdd/*.md` for the content type name in headings

If no GDD found: record as **No GDD** for this content type. Schema cannot be
extracted automatically — see Step 2c.

### 2b — Extract field definitions

Read the GDD. Look for field definitions in this priority order:

**Priority 1 — Explicit field table:**
A markdown table with columns like `Field`, `Name`, `Property`, `Attribute`, `Key`:
```
| Field | Type | Description |
|-------|------|-------------|
| damage_base | int | Base damage before modifiers |
```
Extract all row values from the first column.

**Priority 2 — Explicit field list in Detailed Rules section:**
Look under `## Detailed Rules` for bullet or numbered lists that define fields:
```
- `damage_base` — base damage value
- `equip_slot` — which slot (main_hand, off_hand, both)
```
Extract field names from code-formatted tokens (backtick-wrapped) or colon-delimited lines.

**Priority 3 — Formula references in Formulas section:**
Look under `## Formulas` for variable names used in formulas. Field names referenced
in formula notation are likely required data fields.

**Priority 4 — Prose extraction (fallback):**
Grep for patterns like `[field_name]:`, `"[field_name]"`, or `has a [field_name]` in the
Detailed Rules section. Extract candidate field names.

**After extraction**, classify each candidate field as:
- **Required** — explicitly stated as required, or used in a formula, or listed as a property
- **Optional** — described as optional, conditional, or "if applicable"

### 2c — Confirm field list with user

Present the extracted field list (or empty state if no GDD):

```
Content type: weapons
GDD: design/gdd/weapons.md

Extracted required fields (7):
  ✓ id
  ✓ name
  ✓ damage_base
  ✓ equip_slot
  ✓ rarity
  ✓ icon_path
  ✓ weight

Optional fields (2):
  ○ damage_bonus_type
  ○ special_effect
```

If no GDD found or extraction is ambiguous, show what was found and use `AskUserQuestion`:
- "I couldn't extract a clear field list for **[type]**. What are the required fields?"
- Options: `[A] List them now` / `[B] Skip this type` / `[C] Stop here`

If [A]: accept the user's field list (comma-separated or line-by-line). Store as the
required field contract for this type.

**Do NOT proceed to Phase 3 for a content type without a confirmed field list.**

---

## Phase 3: Inspect Data Files

For each content type with a confirmed field list, inspect every data file.

### 3a — Parse each file

**JSON files:**
Read the file. If it is a JSON array (`[{...}, {...}]`), treat each element as one
instance. If it is a JSON object (`{...}`), treat the entire object as one instance.
Extract the set of top-level keys present.

**YAML files:**
Read the file. If it is a YAML sequence, treat each document as one instance. If it
is a mapping, treat it as one instance. Extract top-level keys.

**CSV files:**
Read only the first row (header row). Column names are the field set. Each subsequent
row is one instance with the same schema — check a sample of 3 rows for empty values.

**Godot `.tres` / `.res` files:**
Grep for `[resource]` or `[ext_resource]` sections. Extract property assignment lines:
`property_name = value`. Keys are the field names.

**Unity `.asset` files:**
Treat as YAML. Extract top-level keys under the main object block.

**If file is unreadable** (malformed JSON/YAML, binary content):
Record as **Parse Error** — cannot check. Note in report.

### 3b — Check field completeness per instance

For each instance (file or array element), compare its keys against the required
field contract for its type.

Classify each field:
- **Present** — key exists AND value is not `null`, `""`, `0` when `0` is not a valid
  game value, or `[]`/`{}` empty collections
- **Missing** — key does not exist
- **Empty** — key exists but value is null, empty string, empty array, or empty object

**Treat `0` as Present** unless the field is a name, ID, path, or reference field
(where 0 is never a valid value).

Record per instance: which fields are Missing, which are Empty.

---

## Phase 4: Build Coverage Report

Compute completeness metrics per content type:

```
[type] completeness:
- Files inspected: N
- Fully complete: M (all required fields present and non-empty)
- Partial: K (some fields missing or empty)
- Parse errors: P (could not read)

Field breakdown:
| Field | Present | Missing | Empty | % Complete |
|-------|---------|---------|-------|------------|
| id | 12 | 0 | 0 | 100% |
| name | 12 | 0 | 0 | 100% |
| damage_base | 10 | 1 | 1 | 83% |
| equip_slot | 8 | 4 | 0 | 67% |
| rarity | 12 | 0 | 0 | 100% |
| icon_path | 5 | 0 | 7 | 42% |
| weight | 3 | 9 | 0 | 25% |
```

Flag severity per field:
- `< 50%` complete → **HIGH** (blocking — this field is mostly absent)
- `50–79%` → **MEDIUM** (partial — some instances missing it)
- `80–99%` → **LOW** (nearly done — a few instances need attention)
- `100%` → **OK**

For each **Partial** file, list which fields are missing:
```
Partial files:
- sword_iron.json — missing: equip_slot, icon_path, weight
- axe_battle.json — missing: weight, icon_path
```

---

## Phase 5: Present Full Report

```
## Data Schema Coverage Report
Date: [date]
Scope: [all types | content-type]

---

### Summary

| Content Type | Files | Complete | Partial | Errors | Schema % |
|---|---|---|---|---|---|
| weapons | 12 | 5 | 7 | 0 | 67% |
| enemies | 8 | 8 | 0 | 0 | 100% |
| abilities | 20 | 14 | 5 | 1 | 70% |
| items | 35 | 30 | 5 | 0 | 86% |

Overall: [N] files, [M] fully complete, [K] partial, [P] parse errors
Schema completeness: [X]% across all required fields

---

### HIGH priority gaps (< 50% field completion)

| Content Type | Field | Complete | Missing | Action |
|---|---|---|---|---|
| weapons | weight | 3/12 (25%) | 9 files | Add weight field to all weapon definitions |
| weapons | icon_path | 5/12 (42%) | 7 empty | Point icon_path to art asset filename |

---

### Per-type detail

#### weapons — 67% complete
[full field breakdown table]

Partial files:
[list]

#### enemies — 100% complete
All 8 enemy files have all required fields present and non-empty.

[...continue per type]

---

### No GDD / no schema defined

| Content Type | Files | Status |
|---|---|---|
| quests | 6 | No GDD found — schema not verified |

---

### Parse errors

| File | Error |
|---|---|
| abilities/ability_broken.yaml | YAML parse error — check file syntax |
```

Present this report to the user.

---

## Phase 6: Optional Actions

Build the option list dynamically — only include options that apply:

- `[_] Write report to docs/data-schema-coverage-[date].md` — include if `--report`
  was passed.

- `[_] Write production/data-roadmap.md — milestone-grouped data production plan` —
  include if `--roadmap` was passed.

- `[_] Run /design-system [type] — add or clarify field definitions in the GDD` —
  include if any content type has **No GDD** or HIGH-severity field gaps.

- `[_] Run /content-audit — compare file counts vs. GDD-specified counts` —
  always include (complementary audit).

- `[_] Run /asset-coverage — check art assets referenced by icon_path fields exist` —
  include if `icon_path`, `sprite`, `texture`, or similar asset-reference fields have
  HIGH or MEDIUM gaps. These gaps mean data files reference assets that may not be
  delivered yet.

- `[_] Stop here`

Assign letters A, B, C… Mark the most actionable as `(recommended)`.

Present via `AskUserQuestion`. Wait for user selection.

---

## Phase 7: Write Report (if selected)

Ask: "May I write the full report to `docs/data-schema-coverage-[date].md`?"

Write using the report format from Phase 5, plus a **Remediation Guide** section:

```markdown
## Remediation Guide

### Fix HIGH gaps first

For each HIGH-severity field, the fastest remediation path:

1. **[field name]** in [type]
   - GDD reference: [section where field is defined]
   - Affected files: [list]
   - Example of correct value from a complete file: `[field]: [value]`

### Files needing the most work

| File | Missing fields | Priority |
|---|---|---|
| [file] | [list] | HIGH / MEDIUM / LOW |
```

Confirm: "Report written to `docs/data-schema-coverage-[date].md`."

---

## Phase 7b: Write data-roadmap.md (if --roadmap selected)

**Only run if `--roadmap` was passed AND user selected this option.**

Ask: "May I write the data production roadmap to `production/data-roadmap.md`?"

If yes, write:

```markdown
# Data Production Roadmap
<!-- Generated by /data-schema-coverage --roadmap on [date] -->
<!-- Regenerate: run `/data-schema-coverage --roadmap` -->

Source: `assets/data/` + GDDs in `design/gdd/`
Last updated: [date]

Legend: ✅ Complete (all fields) · 🔄 Partial (some fields missing) · ❌ Not Started (no files) · ⚠️ No Schema (no GDD field definition)

---

## By Content Type (milestone order)

| Content Type | GDD | Files | Complete | Partial | Schema % | Priority Gaps |
|---|---|---|---|---|---|---|
| weapons | ✅ | 12 | 5 | 7 | 67% | weight, icon_path |
| enemies | ✅ | 8 | 8 | 0 | 100% | — |
| quests | ⚠️ | 6 | — | — | unverified | Define schema first |

---

## HIGH Priority Gaps (< 50% field completion)

| Content Type | Field | Complete | Action |
|---|---|---|---|
| [type] | [field] | N/M (X%) | [specific action] |

---

## Files Needing the Most Work

| File | Missing Fields | Content Type |
|---|---|---|
| [file] | [list] | [type] |

---

## Next Data Production Actions

1. [Most impactful gap — specific file and field]
2. [Second gap]
3. [Third gap]

Skills: `/data-schema-coverage [type]` for focused audit · `/design-system [type]` to define missing schema
```

Confirm: "Data production roadmap written to `production/data-roadmap.md`."

---

## Phase 8: Session State

After any file write, append to `production/session-state/active.md`:

```
## Session Extract — /data-schema-coverage [date]
- Content types audited: [list]
- Files inspected: [N]
- Overall schema completeness: [X]%
- HIGH gaps: [N fields across N types]
- Report written: [yes → path | no]
- Recommended next: [action]
```

If `active.md` does not exist, create it.

---

## Error Handling

**assets/data/ empty or missing** → BLOCKED with note to run `/content-audit` first to
assess implementation progress. No data = nothing to check.

**GDD exists but field extraction yields zero fields** → Treat as ambiguous. Use
`AskUserQuestion` to ask for the field list manually before proceeding.

**All files parse-error** → Report 0 inspectable files for that type. Note: "All
[N] files failed to parse — check file syntax before running this audit."

**Mixed formats in one type directory** → Process each format independently. Report
field presence separately per format if schemas differ.

---

## Complementary Skills

This skill answers: **"Are the data definitions complete?"**

Companion skills for full coverage:

| Question | Skill |
|---|---|
| How many of each content type exist vs. GDD plan? | `/content-audit` |
| Do the referenced art assets exist? | `/asset-coverage` |
| Are data file names and formats correct? | `/asset-audit` |
| Do the GDD files themselves have all 8 required sections? | `/gdd-coverage` |
