---
name: project-gap
description: "Meta-coverage aggregator. Runs lightweight inline scans across all coverage layers (GDD, data schema, asset delivery, story/backlog) and synthesizes a unified, priority-ordered gap list. Answers 'what still needs to be made?' Produces actionable work items grouped by milestone. Optional --stories flag pipes top gaps into /create-stories."
argument-hint: "[milestone] [--stories] [--write]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

When this skill is invoked:

## Parse Arguments

- **`[milestone]`** — optional. Scope to one milestone tier (`mvp`, `vertical-slice`,
  `alpha`, `full-vision`). If absent → all tiers, ordered MVP first.
- **`--stories`** — optional. After presenting gaps, offer to pipe the top gaps
  directly into `/create-stories` as backlog entries.
- **`--write`** — optional. After presenting gaps, offer to write the full report
  to `production/project-gap-[YYYY-MM-DD].md`.

Store all flags for use in later phases.

---

## Phase 1: Load the System Registry

Read `design/gdd/systems-index.md`.

**If missing:**
> "No systems index found. Run `/map-systems` to decompose the game concept into
> systems first, then run `/project-gap` to audit coverage."
> STOP.

Extract for each system:
- Name (canonical)
- Milestone tier (MVP / Vertical Slice / Alpha / Full Vision / Unassigned)
- GDD filename (derive as `design/gdd/[kebab-name].md` if not specified)
- Index Status field value

Apply milestone filter if `[milestone]` argument was passed.

Also read `production/roadmap.yaml` if it exists — use it to confirm milestone
assignments. If it contradicts systems-index, note the discrepancy and use the
systems-index as the primary source.

---

## Phase 2: GDD Layer Scan

For each system in scope, check its GDD.

### 2a — File existence

Glob `design/gdd/*.md`. Exclude: `game-concept.md`, `game-pillars.md`,
`systems-index.md`, files beginning with `gdd-cross-review-`.

Mark each system: **GDD exists** / **No GDD**.

### 2b — Section completeness (existing GDDs only)

For each GDD that exists, grep for the 8 required section headers:
`Overview`, `Player Fantasy`, `Detailed Rules`, `Formulas`, `Edge Cases`,
`Dependencies`, `Tuning Knobs`, `Acceptance Criteria`.

Count sections present (0–8). Assign:
- 8/8 → **GDD Complete**
- 1–7/8 → **GDD Incomplete** — record which sections missing
- 0/8 → **GDD Empty** (file exists but skeleton only)

### 2c — ADR check (for Complete GDDs only)

Glob `docs/architecture/*.md`. Exclude `control-manifest.md`, `README.md`.

For each Complete GDD, check if an ADR exists mentioning the system name.
Mark: **ADR exists** / **No ADR**.

### 2d — GDD gap records

For each system, produce a gap record:

```
{ system, milestone, gap_type: "no_gdd" | "gdd_incomplete" | "no_adr", severity, detail }
```

Severity:
- `no_gdd` + MVP tier → **CRITICAL**
- `no_gdd` + other tier → **HIGH**
- `gdd_incomplete` (< 4 sections) → **HIGH**
- `gdd_incomplete` (4–7 sections) → **MEDIUM**
- `gdd_empty` → **HIGH**
- `no_adr` on Complete MVP GDD → **MEDIUM**
- `no_adr` on Complete non-MVP GDD → **LOW**

---

## Phase 3: Data Layer Scan

For each system in scope with any GDD (complete or not):

### 3a — Data directory check

Derive the expected data directory: `assets/data/[kebab-system-name]/`

Also check common aliases: `assets/data/[plural]/`, `assets/data/[type]/`.

Glob `assets/data/[system-name]/**/*` (and aliases). Record:
- **Data exists** — N files found
- **No data** — directory empty or missing

### 3b — Sample field check (Data exists only)

For systems with data files, read up to 3 files (smallest first to stay fast).

Extract top-level keys from each file (JSON/YAML) or column headers (CSV).

From the GDD (if complete), grep `## Detailed Rules` for backtick-wrapped field
names or explicit field tables.

Compare: what fraction of GDD-defined fields appear in the sampled data files?

- All fields present in sample → **Data Complete (sample)**
- Some fields missing → **Data Partial** — list which fields absent in sample
- No GDD field list → **Data Unverifiable** — cannot check schema

### 3c — Data gap records

```
{ system, milestone, gap_type: "no_data" | "data_partial" | "data_unverifiable", severity, detail }
```

Severity:
- `no_data` + MVP → **HIGH**
- `no_data` + other → **MEDIUM**
- `data_partial` + HIGH missing fields → **MEDIUM**
- `data_unverifiable` → **LOW** (informational)

---

## Phase 4: Asset Layer Scan

Read `design/assets/asset-manifest.md` if it exists.

If missing: skip this phase entirely. Record: "Asset manifest not found — run
`/asset-spec` to create one, then `/asset-coverage` for delivery tracking."

### 4a — Find committed-but-undelivered assets

From the manifest, extract all entries with Status `Done` or `Approved`.

For each, find the Spec File path and grep it for the `| Naming |` field value.

Check if that filename exists anywhere under `assets/`.

### 4b — Count by category

Group missing files by Category (2D Art, Audio, VFX, 3D, UI).

### 4c — Asset gap records

```
{ asset_id, name, category, gap_type: "missing_file", severity, detail }
```

Severity:
- Missing art/audio for MVP system → **HIGH**
- Missing art/audio for other milestone → **MEDIUM**
- Missing file for `Approved` entry → **HIGH** (art director signed off but no file)

---

## Phase 5: Story/Backlog Layer Scan

Check whether designed systems have implementation work tracked.

### 5a — Read backlog

Read `production/backlog.yaml` if it exists. Extract: list of epic names / system
references.

Also glob `production/epics/*/EPIC.md` — extract system names referenced in each.

If neither exists: record "No backlog found" — all designed systems are untracked.

### 5b — Cross-reference

For each system in scope with a GDD:
- **Has epic**: system name appears in backlog or epics directory
- **No epic**: system has a GDD but no backlog entry

### 5c — Story gap records

```
{ system, milestone, gap_type: "no_epic", severity, detail }
```

Severity:
- `no_epic` + MVP + Complete GDD → **HIGH** (designed but not in sprint pipeline)
- `no_epic` + MVP + Incomplete GDD → **MEDIUM** (GDD not done yet — epic premature)
- `no_epic` + other milestone → **LOW**

---

## Phase 6: Synthesize and Prioritize

Merge all gap records from Phases 2–5 into one list.

### 6a — Deduplication / root-cause collapse

If a system has BOTH `no_gdd` AND `no_data` AND `no_epic` gaps: collapse into one
root-cause entry:
> "[System] — No GDD, no data, no epic. Root cause: GDD authoring not started.
> Fix GDD first; data and epic follow."

Only list downstream gaps separately when the upstream is resolved. Don't flood
the report with 4 gaps that all trace to "no GDD."

### 6b — Sort order

Primary: severity (CRITICAL → HIGH → MEDIUM → LOW)
Secondary: milestone tier (MVP → Vertical Slice → Alpha → Full Vision)
Tertiary: gap type (no_gdd → gdd_incomplete → no_data → missing_asset → no_epic)

### 6c — Assign work items

For each gap (or collapsed root-cause), produce one actionable work item:

```
[SEVERITY] [Milestone] — [System or Asset]: [one-sentence gap description]
→ Next action: [exact skill to run, e.g., /design-system combat]
```

Examples:
```
[CRITICAL] MVP — Enemy AI: No GDD exists. Data and epic cannot be created until GDD is authored.
→ Next action: /design-system enemy-ai

[HIGH] MVP — Weapons: GDD complete but 9/12 weapon files missing weight and icon_path fields.
→ Next action: /data-schema-coverage weapons

[HIGH] MVP — Combat VFX: 7 assets marked Done in manifest but files not found in assets/vfx/.
→ Next action: /asset-coverage

[MEDIUM] MVP — Inventory System: GDD complete, data exists, but no epic in backlog.
→ Next action: /create-epics inventory-system
```

---

## Phase 7: Present the Report

```
## Project Gap Report
Date: [date]
Scope: [all milestones | milestone-name]

---

### Health Summary

| Layer | Total in scope | Gaps found | Critical | High | Medium | Low |
|---|---|---|---|---|---|---|
| GDD (design docs) | [N] systems | [N] gaps | [N] | [N] | [N] | [N] |
| Data (content files) | [N] systems | [N] gaps | — | [N] | [N] | [N] |
| Assets (delivery) | [N] assets | [N] gaps | — | [N] | [N] | [N] |
| Stories (backlog) | [N] systems | [N] gaps | — | [N] | [N] | [N] |

Overall project completeness (MVP only): [X]%
[Calculated as: fully-covered MVP systems / total MVP systems × 100]
A system is "fully covered" when: GDD complete + data exists + assets on track + epic in backlog.

---

### CRITICAL gaps — fix before anything else

[Work items, or "None"]

---

### HIGH gaps — fix this sprint

[Work items]

---

### MEDIUM gaps — fix this milestone

[Work items]

---

### LOW gaps — track but not urgent

[Work items]

---

### Coverage intact (no gaps)

[List systems with all four layers complete, or "None yet"]

---

### Roadmap files status

| Roadmap | Path | Status |
|---|---|---|
| System scope | `production/roadmap.yaml` | [✅ exists / ❌ missing] |
| Doc authoring | `production/doc-roadmap.md` | [✅ exists / ❌ missing — run /gdd-coverage --roadmap] |
| Asset production | `production/asset-roadmap.md` | [✅ exists / ❌ missing — run /asset-coverage --roadmap] |
| Data production | `production/data-roadmap.md` | [✅ exists / ❌ missing — run /data-schema-coverage --roadmap] |
```

Present this report in the conversation.

---

## Phase 8: Optional Actions

Build dynamically — only include applicable options:

- `[_] Write production/project-gap-[date].md — full gap report` — include if
  `--write` was passed.

- `[_] Create stories for top [N] HIGH gaps — /create-stories` — include if
  `--stories` was passed AND there are HIGH/CRITICAL gaps with no epic. Name the
  specific systems.

- `[_] Run /design-system [system] — author the highest-priority missing GDD` —
  include if any CRITICAL gap exists. Name the actual system.

- `[_] Generate all roadmap files — run /gdd-coverage --roadmap, /asset-coverage
  --roadmap, /data-schema-coverage --roadmap` — include if any roadmap file is
  missing. This updates all three in sequence.

- `[_] Run /gdd-coverage --update-index — sync status fields to filesystem reality` —
  include if any GDD status mismatch detected.

- `[_] Stop here`

Assign letters A, B, C… Mark most pipeline-advancing as `(recommended)`.

Present via `AskUserQuestion`. Wait for selection.

---

## Phase 9: Write Gap Report (if selected)

Ask: "May I write the gap report to `production/project-gap-[date].md`?"

Write using the Phase 7 format, plus a **Next Sprint Candidates** section:

```markdown
## Next Sprint Candidates

Based on gap severity and milestone priority, these items are candidates for
the next sprint plan:

1. [work item — system, gap type, action]
2. [work item]
3. [work item]
…

Run `/sprint-plan` and reference this file to populate the next sprint.
```

Confirm: "Gap report written to `production/project-gap-[date].md`."

---

## Phase 10: Session State

After any file write, append to `production/session-state/active.md`:

```
## Session Extract — /project-gap [date]
- Scope: [milestone or all]
- Systems scanned: [N]
- Critical gaps: [N]
- High gaps: [N]
- MVP completeness: [X]%
- Report written: [yes → path | no]
- Top recommended action: [work item]
```

If `active.md` does not exist, create it.

---

## Design Principles

**Root-cause first.** Don't list 4 gaps that all stem from "no GDD." List the
root cause once. Downstream gaps are implied and listed only when the root is
resolved.

**Actionable always.** Every gap entry ends with a specific skill to run. No
vague "address this gap" language.

**Lightweight scan, not full audit.** This skill reads source files directly and
samples data files (max 3 per type). It does not spawn the full interactive flows
of `/gdd-coverage`, `/asset-coverage`, or `/data-schema-coverage`. For deep
per-system analysis, run those skills individually with `--report`.

**Roadmap awareness.** Always show roadmap file status in the report so the user
knows at a glance whether the per-layer planning documents exist.

---

## Complementary Skills

| Need | Skill |
|---|---|
| Deep GDD coverage audit | `/gdd-coverage` |
| Deep asset delivery audit | `/asset-coverage` |
| Deep data schema audit | `/data-schema-coverage` |
| Approximate content count vs. GDD | `/content-audit` |
| Generate epics from GDDs | `/create-epics` |
| Plan next sprint from gaps | `/sprint-plan` |
| Formal milestone gate | `/gate-check` |
