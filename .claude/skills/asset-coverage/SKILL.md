---
name: asset-coverage
description: "Audit asset delivery coverage: cross-references design/assets/asset-manifest.md entries against actual files in assets/. Detects missing files, orphan files, and status mismatches. Optional --update-manifest syncs Status fields to filesystem reality. Optional --roadmap writes a milestone-grouped asset production plan."
argument-hint: "[--roadmap] [--update-manifest]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

When this skill is invoked:

## Parse Arguments

Scan `$ARGUMENTS` for flags (order doesn't matter, can combine):
- `--roadmap` → after the coverage report, offer to write `production/asset-roadmap.md`
- `--update-manifest` → after the coverage report, offer to update Status fields in the manifest

Store both as booleans for use in later phases.

---

## Phase 1: Prerequisites

### 1a — Locate manifest

Read `design/assets/asset-manifest.md`.

**If the file does not exist**, stop immediately:
> "No asset manifest found at `design/assets/asset-manifest.md`. Run `/asset-spec` first
> to inventory and spec the game's assets, then come back to check coverage."

### 1b — Extract asset registry

Parse every asset row from the manifest. Each row follows this format:
```
| ASSET-NNN | [name] | [category] | [status] | [spec file path] |
```

For each asset, record:
- **Asset ID** (e.g., `ASSET-001`)
- **Name**
- **Category** (`Sprite / 2D Art`, `VFX / Particles`, `Environment`, `UI`, `Audio`, `3D Assets`, or other)
- **Current manifest Status** (`Needed`, `In Progress`, `Done`, `Approved`)
- **Spec File** path (relative, e.g., `design/assets/specs/combat-assets.md`)

Group assets by Category. Store the full registry — it is the source of truth for what should exist.

### 1c — Read entity inventory (if exists)

Read `design/assets/entity-inventory.md` if it exists.

Extract any inventory entries whose Status differs from the manifest (e.g., marked `Needed` in inventory but no manifest entry at all). Record these as **inventory-only entries** — they have been inventoried but not yet specced.

---

## Phase 2: Extract Expected Filenames

For each asset in the registry with a Spec File:

1. Read the spec file (if not already read; batch by spec file to avoid re-reads).
2. Find the ASSET-NNN block matching the Asset ID:
   ```
   ## ASSET-NNN — [name]
   ```
3. Extract the `Naming` field value from that block's table:
   ```
   | Naming | [filename.ext] |
   ```
4. Record the expected filename. If no Naming field is found, record as **No naming spec**.

Assets with **No naming spec** cannot be file-checked. Note them separately — they need spec completion before delivery can be verified.

---

## Phase 3: Filesystem Scan

### 3a — Scan asset directories

Glob all files in the asset delivery tree:
- `assets/art/**/*`
- `assets/audio/**/*`
- `assets/vfx/**/*`
- `assets/shaders/**/*`
- `assets/3d/**/*`
- `assets/ui/**/*`
- `assets/video/**/*`

Also try `assets/**/*` as a fallback catch-all in case the project uses flat or custom subdirectory names.

Exclude directories themselves — record only files.

Record the full filesystem set as a flat list of filenames (basename only, for matching) plus their full relative paths.

### 3b — Map categories to directories

Use this heuristic mapping to narrow file checks:

| Manifest Category | Expected asset dirs |
|---|---|
| Sprite / 2D Art | `assets/art/`, `assets/ui/` |
| VFX / Particles | `assets/vfx/`, `assets/art/` |
| Environment | `assets/art/`, `assets/3d/` |
| UI | `assets/ui/`, `assets/art/` |
| Audio | `assets/audio/` |
| 3D Assets | `assets/3d/`, `assets/art/` |

If the filesystem scan found no files in any subdirectory, note: "No delivered assets found in `assets/` — project may be pre-production."

---

## Phase 4: Cross-Reference

For each asset in the registry:

**A. File existence check**

If the asset has an expected filename (from Phase 2):
- Search the filesystem set for a file with that basename.
- Match is case-insensitive (filesystem may differ by platform).
- Record: **File found** / **File missing**.

If the asset has **No naming spec**:
- Record: **Cannot verify — no naming spec**.

**B. Assign filesystem status**

Based on file existence and current manifest Status:

| Manifest Status | File exists? | Filesystem Status | Flag |
|---|---|---|---|
| `Done` or `Approved` | Yes | OK | — |
| `Done` or `Approved` | No | **MISSING FILE** | ⚠️ |
| `Needed` or `In Progress` | Yes | **AHEAD** | ℹ️ |
| `Needed` or `In Progress` | No | Expected | — |
| Any | No naming spec | **UNVERIFIABLE** | ℹ️ |

**NEVER auto-promote or auto-demote `Approved` status** — that is set by art director sign-off and cleared only by a human decision. Record the mismatch but do not change it in Phase 6 without explicit flag.

**C. Identify orphan files**

Any file in the filesystem set whose basename does NOT match any expected filename from any spec is an **orphan**. Orphans may be:
- Delivered assets not yet added to the manifest
- Leftover files from removed/renamed assets
- WIP files not linked to a spec

---

## Phase 5: Build Coverage Report

Present this report to the user before taking any further action.

```
## Asset Coverage Report
Date: [date]
Manifest entries: [N] assets across [N] spec files
Delivered files found: [N] files in assets/

---

### Coverage by Category

#### Sprite / 2D Art ([N] assets)
| Asset ID | Name | Manifest Status | Expected File | File Found | Flag |
|---|---|---|---|---|---|
| ASSET-001 | [name] | Needed | [filename or —] | — | — |
| ASSET-002 | [name] | Done | [filename] | ✅ | — |
| ASSET-003 | [name] | Done | [filename] | ❌ | ⚠️ MISSING |

#### VFX / Particles ([N] assets)
[same table]

#### Environment ([N] assets)
[same table]

#### UI ([N] assets)
[same table]

#### Audio ([N] assets)
[same table]

#### 3D Assets ([N] assets)
[same table]

---

### Summary

| Metric | Count |
|---|---|
| OK (Done/Approved + file exists) | [N] |
| Missing (Done/Approved + no file) | [N] |
| Ahead (Needed/In Progress + file exists) | [N] |
| Unverifiable (no naming spec) | [N] |
| Not yet started (Needed + no file, expected) | [N] |
| Orphan files (no manifest entry) | [N] |
| Inventory-only (specced but no manifest row) | [N] |

Asset delivery: [OK + Ahead] / [Done + Approved] ([X]%) of committed assets delivered.

---

### Orphan Files (delivered with no manifest entry)

[List files, or "None"]

---

### Status Mismatches (⚠️ action needed)

[List each MISSING FILE mismatch with exact Asset ID, name, and expected filename, or "None"]

---

### Unverifiable Assets (no naming spec in spec file)

[List Asset IDs and names, or "None — all specced assets have naming fields"]
```

---

## Phase 6: Optional Actions

After presenting the report, build the option list dynamically — only include options that apply:

**Option pool:**

- `[_] Update asset-manifest.md — sync [N] status fields` — include if `--update-manifest` was passed AND there are mismatches or AHEAD entries. Never auto-update without explicit flag + user confirmation.

- `[_] Write production/asset-roadmap.md — full milestone asset production plan` — include if `--roadmap` was passed.

- `[_] Run /asset-spec — complete naming specs for [N] unverifiable assets` — include if any assets have no naming spec.

- `[_] Run /asset-audit — validate delivered assets for naming, format, and size compliance` — always include if any files were found in `assets/`.

- `[_] Stop here`

Assign letters A, B, C… to included options. Mark the most pipeline-advancing as `(recommended)`.

Present via `AskUserQuestion`. Wait for user selection before proceeding.

---

## Phase 7: Update asset-manifest.md (if selected)

**Only run if `--update-manifest` was passed AND user selected this option.**

For each status mismatch, update the Status field in `design/assets/asset-manifest.md`.

**Rules:**
- `Needed` → `Done` only if file is confirmed present AND manifest was `Needed` or `In Progress`
- `Done` → preserve (missing file is a production gap, not a status rollback — flag it, don't revert)
- **NEVER change `Approved`** — that status is set by art director sign-off only

After updating, confirm: "Updated [N] status fields in `design/assets/asset-manifest.md`."

Also update the **Progress Summary** header counts at the top of the manifest.

---

## Phase 8: Write asset-roadmap.md (if selected)

**Only run if `--roadmap` was passed AND user selected this option.**

Ask: "May I write the asset production roadmap to `production/asset-roadmap.md`?"

If yes, write the file using this format:

```markdown
# Asset Production Roadmap
<!-- Generated by /asset-coverage --roadmap on [date] -->
<!-- Regenerate: run `/asset-coverage --roadmap` -->

Source: `design/assets/asset-manifest.md`
Last updated: [date]

Tracks asset delivery status across all categories.

Legend: ✅ Delivered & Approved · 🔄 In Progress · ❌ Needed · ⚠️ Missing (committed but not delivered)

---

## By Category

### Sprite / 2D Art ([N] assets)

| Asset ID | Name | Status | File | Spec |
|---|---|---|---|---|
| ASSET-001 | [name] | [emoji] | [filename or —] | [spec file] |

### VFX / Particles
[same table]

### Environment
[same table]

### UI
[same table]

### Audio
[same table]

### 3D Assets
[same table]

---

## Production Gaps

### Missing files (committed but not delivered)
[List of ASSET-NNN entries marked Done/Approved with no file found, or "None"]

### Unspecced assets (in inventory but no manifest row)
[List from entity-inventory.md inventory-only entries, or "None"]

### Orphan files (delivered but not in manifest)
[List of filesystem files with no manifest entry, or "None"]

---

## Next Production Actions

1. [Highest-priority gap — most specific, actionable]
2. [Second gap]
3. [Third gap]

Skills: `/asset-spec` for spec gaps · `/asset-audit` for compliance · `/taste-gate [name]` before batch AI generation
```

After writing, confirm: "Asset production roadmap written to `production/asset-roadmap.md`."

---

## Phase 9: Session State

After any file write (manifest update or roadmap), append to
`production/session-state/active.md`:

```
## Session Extract — /asset-coverage [date]
- Assets in manifest: [N]
- Delivery rate: [N]/[N committed] ([X]%)
- Missing files flagged: [N]
- Orphan files: [N]
- Manifest status fields updated: [N, or "—"]
- Asset roadmap written: [yes → production/asset-roadmap.md | no]
- Recommended next: [action from Phase 6 option list]
```

If `active.md` does not exist, create it with this block as initial content.

---

## Error Handling

**asset-manifest.md missing** → BLOCKED with message pointing to `/asset-spec`.

**assets/ directory empty or missing** → Report 0 delivered files. Do not fail. Coverage is 0%; this is valid pre-production state.

**Spec file referenced in manifest does not exist** → Note: "Spec file `[path]` not found — [N] assets from this spec cannot be file-checked." Count those assets as Unverifiable.

**Spec file exists but ASSET-NNN block not found** → Note: "No block for [ASSET-NNN] in `[spec file]` — cannot extract naming. Mark Unverifiable."

**design/assets/entity-inventory.md missing** → Skip inventory-only check. Do not fail.

---

## Collaborative Protocol

- **Never auto-write files.** Always ask before writing manifest updates or roadmap.
- **Never auto-change `Approved` status.** That flag is set by the art director and cleared only by human decision.
- **Present the full report first.** Do not ask for action until the user has seen the coverage data.
- **Be specific.** Every mismatch, orphan, and gap cites the exact Asset ID, filename, and spec path — no vague summaries.
