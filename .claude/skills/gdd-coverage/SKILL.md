---
name: gdd-coverage
description: "Audit GDD file coverage against systems-index.md and verify 8-section completeness per GDD. Optional --roadmap flag writes a milestone-grouped documentation plan (GDDs + ADRs) to production/doc-roadmap.md. Optional --update-index flag syncs systems-index.md status fields to match filesystem reality."
argument-hint: "[--roadmap] [--update-index]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

When this skill is invoked:

## Parse Arguments

Scan `$ARGUMENTS` for flags (order doesn't matter, can combine):
- `--roadmap` → after the coverage report, offer to write `production/doc-roadmap.md`
- `--update-index` → after the coverage report, offer to update status fields in `systems-index.md`

Store both as booleans for use in later phases.

---

## Phase 1: Prerequisites

### 1a — Locate systems index

Read `design/gdd/systems-index.md`.

**If the file does not exist**, stop immediately:
> "No systems index found at `design/gdd/systems-index.md`. Run `/map-systems` first
> to decompose the game concept into systems and create the index."

### 1b — Extract system registry

From the systems index, extract for each system:
- System name (canonical)
- GDD filename (if the index specifies one; otherwise derive as `design/gdd/[kebab-name].md`)
- Milestone tier (MVP / Vertical Slice / Alpha / Full Vision / Unassigned)
- Current index Status field value

Group systems by milestone tier. Store the full registry — it is the source of truth.

### 1c — Establish the 8 required sections

The required GDD sections (from `coding-standards.md`) are:
1. `Overview`
2. `Player Fantasy`
3. `Detailed Rules`
4. `Formulas`
5. `Edge Cases`
6. `Dependencies`
7. `Tuning Knobs`
8. `Acceptance Criteria`

These exact strings are used for all completeness checks. Do not add, remove, or rename them.

---

## Phase 2: GDD Filesystem Scan

### 2a — Find all GDD files

Glob `design/gdd/*.md`.

Exclude from coverage analysis:
- `game-concept.md`
- `game-pillars.md`
- `systems-index.md`
- Any file whose name begins with `gdd-cross-review-` (review outputs)

Record the resulting set as the **filesystem GDD set**.

### 2b — Identify orphan GDDs

Any file in the filesystem GDD set that does NOT correspond to a system in the
index is an **orphan**. Record orphans separately — they may be stale files,
renamed systems, or undocumented additions.

### 2c — Check section completeness for each GDD

For each system in the index:

1. **GDD exists?** — check if the system's GDD file is in the filesystem GDD set.
   - If NO → Status = `Not Started`. Skip to next system.

2. **Section completeness** — for each GDD that exists, grep it for each of the
   8 required section headers. A section is "present" if any of these patterns
   match (case-insensitive, `##` or `#` prefix accepted):

   ```
   ## Overview
   ## Player Fantasy
   ## Detailed Rules
   ## Formulas
   ## Edge Cases
   ## Dependencies
   ## Tuning Knobs
   ## Acceptance Criteria
   ```

   Count how many of the 8 sections are present (0–8).

3. **Assign filesystem status:**
   - 0 sections present (file exists but is empty/skeleton) → `Not Started`
   - 1–7 sections present → `In Progress`
   - All 8 present → `Complete`
   - Current index status is `Needs Revision` → preserve as `Needs Revision` regardless
     of section count (do not auto-promote; revision decision belongs to the human)

4. **Flag status mismatch** — if the filesystem status differs from the index Status field
   (excluding `Needs Revision` which is intentionally preserved):

   ```
   ⚠️  Status mismatch — [system-name]
   Index says: [index status]
   Filesystem: [filesystem status] ([N]/8 sections present)
   ```

---

## Phase 3: ADR Scan (always run; used in report and --roadmap)

### 3a — Find ADR files

Glob `docs/architecture/*.md`.

Exclude:
- `control-manifest.md` (not an ADR)
- `README.md`

The remaining `.md` files are ADRs.

### 3b — Check ADR completeness

For each ADR file, grep for these required section headers:
- `Status:`
- `Context`
- `Decision`
- `Consequences`
- `GDD Requirements Addressed`

Record: how many of the 5 are present, and the value of the `Status:` field
(`Proposed`, `Accepted`, or `Superseded`).

### 3c — Map ADRs to systems (best-effort)

For each ADR, check its `GDD Requirements Addressed` section content or filename
for system names that match the systems registry. Record the mapping where found.
Systems with no ADR mapping are noted as "No ADR" in the report.

### 3d — Check control manifest

Check if `docs/architecture/control-manifest.md` exists. Record: exists / missing.

---

## Phase 4: Build Coverage Report

Build the full report as a structured text block. Use this format:

```
## GDD Coverage Report
Date: [date]
Systems in index: [N]
GDD files on filesystem: [N]

---

### Coverage by Milestone

#### MVP ([N] systems)
| System | GDD File | Index Status | Filesystem | Sections | Mismatch |
|--------|----------|-------------|------------|---------|---------|
| [name] | [file] | [status] | [status] | [N]/8 | ⚠️ / — |

#### Vertical Slice ([N] systems)
[same table]

#### Alpha ([N] systems)
[same table]

#### Full Vision ([N] systems)
[same table]

#### Unassigned ([N] systems)
[same table]

---

### Summary

| Metric | Count |
|--------|-------|
| Complete (8/8 sections) | [N] |
| In Progress (partial sections) | [N] |
| Not Started (no file) | [N] |
| Needs Revision (flagged by review) | [N] |
| Status mismatches | [N] |

GDD coverage: [N complete + in progress] / [total] ([X]%)

---

### Orphan GDDs (files with no index entry)

[List files, or "None"]

---

### ADR Coverage

| System | ADR File | Status | Sections |
|--------|----------|--------|----------|
| [name] | [file or "—"] | [status or "—"] | [N]/5 |

Control manifest: [exists / MISSING]
TR registry: [populated / empty]

---

### Status Mismatches

[List each mismatch with ⚠️, or "None"]
```

Present this report to the user in the conversation before taking any further action.

---

## Phase 5: Optional Actions

After presenting the report, determine which actions to offer based on findings
and flags. Build the option list dynamically — only include options that apply:

**Option pool:**

- `[_] Update systems-index.md — sync [N] mismatched status fields` — include if
  `--update-index` was passed AND there are status mismatches. Never auto-update
  without explicit flag + user confirmation.

- `[_] Write production/doc-roadmap.md — full milestone documentation plan` —
  include if `--roadmap` was passed.

- `[_] Run /design-system [next system name] — author the next Not Started MVP GDD` —
  always include if any MVP GDD is Not Started. Name the actual next system in
  design order from the index.

- `[_] Run /architecture-decision — create an ADR for [system with no ADR]` —
  include if any Complete or In-Progress MVP GDD has no corresponding ADR.

- `[_] Stop here`

Assign letters A, B, C… to included options. Mark the most pipeline-advancing as
`(recommended)`.

Present via `AskUserQuestion`. Wait for user selection before proceeding.

---

## Phase 6: Update systems-index.md (if selected)

**Only run if `--update-index` was passed AND user selected this option.**

For each mismatched system, update the Status field in `systems-index.md` to
the filesystem-derived status.

**Exact status strings only.** Never write:
- `Not Started (no GDD file)`
- `Complete — all sections present`
- Any parenthetical or annotation

Only write: `Not Started` / `In Progress` / `Complete`

Do NOT change any status that is currently `Needs Revision` — that flag was
set by `/review-all-gdds` and is cleared only by a design revision + re-review.

After updating, confirm: "Updated [N] status fields in `systems-index.md`."

---

## Phase 7: Write doc-roadmap.md (if selected)

**Only run if `--roadmap` was passed AND user selected this option.**

Ask: "May I write the documentation roadmap to `production/doc-roadmap.md`?"

If yes, write the file using this format:

```markdown
# Documentation Roadmap
<!-- Generated by /gdd-coverage --roadmap on [date] -->
<!-- Regenerate: run `/gdd-coverage --roadmap` -->

Source: `design/gdd/systems-index.md`
Last updated: [date]

Tracks three doc types per system:
- **GDD** — Game Design Document (`design/gdd/`)
- **ADR** — Architecture Decision Record (`docs/architecture/`)
- **TR IDs** — Technical Requirements in TR registry (`docs/architecture/tr-registry.yaml`)

Legend: ✅ Complete · 🔄 In Progress · ❌ Not Started · 🔁 Needs Revision

---

## MVP

| System | GDD | Sections | ADR | TR IDs |
|--------|-----|----------|-----|--------|
| [name] | [✅/🔄/❌/🔁] | [N]/8 | [✅/❌ filename or —] | [N registered / none] |

**GDD authoring order** (from systems index):
1. [system in design order, if specified]
2. …

**ADR gaps** — systems with Complete GDDs but no ADR:
- [list, or "None"]

---

## Vertical Slice

[same table]

---

## Alpha

[same table]

---

## Full Vision

[same table]

---

## Unassigned

[same table]

---

## Shared Infrastructure Docs

| Document | Path | Status |
|---------|------|--------|
| Control Manifest | `docs/architecture/control-manifest.md` | [✅ exists / ❌ missing] |
| TR Registry | `docs/architecture/tr-registry.yaml` | [✅ populated / ❌ empty] |
| Domain Glossary | `docs/CONTEXT.md` | [✅ exists / ❌ missing] |

---

## Next Documentation Actions

1. [Highest-priority gap — most specific, actionable]
2. [Second gap]
3. [Third gap]

Skill to run: `/design-system [name]` for GDD gaps · `/architecture-decision` for ADR gaps
```

After writing, confirm: "Documentation roadmap written to `production/doc-roadmap.md`."

---

## Phase 8: Session State

After any file write (index update or doc-roadmap), append to
`production/session-state/active.md`:

```
## Session Extract — /gdd-coverage [date]
- GDD coverage: [N]/[total] ([X]%)
- Status mismatches resolved: [N, or "—"]
- Doc roadmap written: [yes → production/doc-roadmap.md | no]
- MVP GDDs not started: [comma-separated list, or "None"]
- Recommended next: [action from Phase 5 option list]
```

If `active.md` does not exist, create it with this block as initial content.

---

## Error Handling

**systems-index.md missing** → BLOCKED with message pointing to `/map-systems`.

**design/gdd/ directory empty** → report 0 GDDs found, all systems `Not Started`.
  Do not fail. The coverage report is still valid: 0% coverage.

**GDD file exists but is unreadable** → note in report: "Could not read [file] —
  manual check required." Do not count as Complete or In Progress.

**docs/architecture/ missing** → report 0 ADRs found, all systems "No ADR".
  Do not fail.

---

## Collaborative Protocol

- **Never auto-write files.** Always ask before writing `systems-index.md` updates
  or `doc-roadmap.md`.
- **Never auto-change `Needs Revision` status.** That flag is set by `/review-all-gdds`
  and cleared only by the human after addressing the review findings.
- **Present the full report first.** Do not ask for action until the user has seen
  the coverage data.
- **Be specific.** Every mismatch, orphan, and gap cites the exact filename and
  system name — no vague summaries.
